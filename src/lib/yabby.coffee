mongoose = require 'mongoose'
{User, Passwd, OauthToken, Tweet, Comment, File, Like, CommentLike, Favorite,
  Channel, ChannelTweet, Sequence, UserView} = require './models'
async = require 'async'
crypto = require 'crypto'
urlparse = require('url').parse
util = require 'underscore'
fs = require 'fs'
uuid = require('uuid').v4
UPYun = require 'upyun'

password_salt = 'IW~#$@Asfk%*(skaADfd3#f@13l!sa9'

hashed_password = (raw_password) ->
  return crypto.createHmac('sha1', password_salt).update(raw_password).digest('hex')

class Yabby
  constructor: (@config) ->
    mongoose.connect @config.mongod
    @upyun = UPYun @config.upyun.bucket, @config.upyun.username, @config.upyun.passwd

  create_user: (user, callback) ->
    self = @
    async.waterfall [
      (next) ->
        User.findOne username: user.username, (err, u) ->
          return next 'User already exists' if u
          next()
      (next) ->
        Passwd.findOne email: user.email, (err, pwd) ->
          return next 'email already exists' if pwd
          next()
      (next) ->
        u = new User {
          username: user.username
          avatar: user.avatar
        }
        u.save (err, u, count) ->
          next err, u
      (u, next) ->
        hash = hashed_password user.passwd
        pwd = new Passwd {
          user_id: u.user_id
          email: user.email
          passwd: hash
        }
        pwd.save (err, pwd, count) ->
          next err, pwd
    ], (err, result) ->
      callback err

  get_user: (user_id, callback) ->
    User.findOne user_id: user_id, (err, user) ->
      return callback 'User not found' unless user
      user = user.toJSON()
      user.avatar = JSON.parse(user.avatar) if user.avatar
      callback null, user

  create_tweet: (tweet, callback) ->
    if not tweet.text or tweet.text.length > 150
      return callback 'Invalid text'

    tweet = new Tweet tweet
    tweet.save (err, tweet) ->
      return callback 'Create tweet fail' if err
      User.findOneAndUpdate {user_id: tweet.user_id}, {$inc: {tweet_count: 1}}, (err, user) ->
        callback null, {}

  get_tweet: (tweet_id, callback) ->
    self = @
    Tweet.findOne tweet_id: tweet_id, (err, tweet) ->
      return callback 'tweet is not exists' unless tweet
      async.parallel {
        user: (next) ->
          return next null unless tweet.user_id
          self.get_user tweet.user_id, (err, user) ->
            next null, user
        file: (next) ->
          return next null unless tweet.file_id
          User.findOne file_id: tweet.file_id, (err, file) ->
            file = file.toJSON() if file
            next null, file

      }, (err, results) ->
        tweet = tweet.toJSON()
        tweet.user = results.user
        tweet.file = results.file

        callback null, tweet

  del_tweet: (tweet, callback) ->
    self = @
    async.waterfall [
      (next) ->
        Tweet.findOneAndRemove tweet, (err, t) ->
          return next err if err
          return next 'tweet not exists' unless t
          next()
      (next) ->
        limit = 1000
        _remove = () ->
          Comment.find {tweet_id: tweet.tweet_id}, null, {limit: limit}, (err, comments) ->
            return next() if err
            return next() if comments.length is 0
            async.eachLimit comments, 5, (comment, next) ->
              User.findOneAndUpdate {user_id: comment.user_id}, {$inc: {comment_count: -1}}, (err) ->
                comment.remove (err) ->
                  next()
            , (err) ->
              _remove()
      (next) ->
        User.findOneAndUpdate {user_id: tweet.user_id}, {$inc: {tweet_count: -1}}, (err, user) ->
          next()
    ], (err) ->
      callback err

  get_tweets: (query, options, callback) ->
    Tweet.find query, null, options, (err, tweets) ->
      return callback 'there if not tweets' if err
      return callback null, [] if tweets.length is 0
      async.parallel {
        users: (next) ->
          user_ids = tweets.map (tweet) ->
            return tweet.user_id

          return next null, {} if user_ids.length is 0

          User.find user_id: {$in: user_ids}, (err, users) ->
            ret = {}
            users.forEach (user) ->
              user = user.toJSON()
              user.avatar = JSON.parse(user.avatar) if user.avatar
              ret[user.user_id] = user
            next null, ret
        files: (next) ->
          file_ids = tweets.map (tweet) ->
            return tweet.file_id
          file_ids = file_ids.filter (file_id) ->
            return file_id
          return next null, {} if file_ids.length is 0
          File.find file_id: {$in :file_ids}, (err, files) ->
            ret = {}
            files.forEach (file) ->
              ret[file.file_id] = file.toJSON()
            next null, ret
      }, (err, results) ->
        tweets = tweets.map (tweet) ->
          tweet = tweet.toJSON()
          tweet.file = results.files[tweet.file_id] if tweet.file_id
          tweet.user = results.users[tweet.user_id]
          return tweet
        callback null, tweets

  create_comment: (comment, callback) ->
    comment = new Comment comment
    comment.save (err, comment) ->
      return callback 'comment fail' if err
      async.parallel [
        (next) ->
          Tweet.findOneAndUpdate {tweet_id: comment.tweet_id}, {$inc: {comment_count: 1}}, (err, tweet) ->
            next null
        (next) ->
          User.findOneAndUpdate {user_id: comment.user_id}, {$inc: {comment_count: 1}}, (err, user) ->
            next null
      ], (err) ->
        callback null

  get_comments: (query, options, callback) ->
    Comment.find query, null, options, (err, comments) ->
      return callback 'not comments' if err or comments.length is 0
      user_ids = comments.map (comment) ->
        return comment.user_id

      User.find user_id: {$in: user_ids}, (err, users) ->
        _users = {}
        users.forEach (user) ->
          user = user.toJSON()
          user.avatar = JSON.parse(user.avatar) if user.avatar
          _users[user.user_id] = user

        comments = comments.map (comment) ->
          comment = comment.toJSON()
          comment.user = _users[comment.user_id]
          return comment

        callback null, comments

  del_comment: (comment, callback) ->
    Comment.findOneAndRemove comment, (err, comment) ->
      return callback err if err
      return callback 'the comment is not exists' unless comment
      async.parallel [
        (next) ->
          User.findOneAndUpdate {user_id: comment.user_id}, {$inc: {comment_count: -1}}, next
        (next) ->
          Tweet.findOneAndUpdate {tweet_id: comment.tweet_id}, {$inc: {comment_count: -1}}, next
      ], (e) ->
        callback err

  like: (like, callback) ->
    Like.findOne {user_id: like.user_id, tweet_id: like.tweet_id}, (err, _like) ->
      if _like
        if _like.is_like is like.is_like
          callback 'you are already like or unlike it'
        else
          if _like.is_like and not like.is_like
            _like.remove (err) ->
              return callback 'you cant like it' if err
              Tweet.findOneAndUpdate {tweet_id: like.tweet_id}, {$inc: {like_count: -1}}, (err, tweet) ->
                callback null
          else
            _like.remove (err) ->
              return callback 'you cant unlike it' if err
              Tweet.findOneAndUpdate {tweet_id: like.tweet_id}, {$inc: {unlike_count: -1}}, (err, tweet) ->
                callback null
            _like.remove callback
      else
        _like = new Like like
        _like.save (err, _like) ->
          return callback 'you are already like or unlike it' if err
          if _like.is_like
            Tweet.findOneAndUpdate {tweet_id: like.tweet_id}, {$inc: {like_count: 1}}, (err, tweet) ->
              callback null
          else
            Tweet.findOneAndUpdate {tweet_id: like.tweet_id}, {$inc: {unlike_count: 1}}, (err, tweet) ->
              callback null

  comment_like: (like, callback) ->
    CommentLike.findOne {user_id: like.user_id, comment_id: like.comment_id}, (err, _like) ->
      if _like
        _like.remove (err) ->
          return callback 'your cant unlike the comment' if err
          Comment.findOneAndUpdate {tweet_id: like.comment_id}, {$inc: {like_count: -1}}, (err, comment) ->
            callback null
      else
        _like = new CommentLike like
        _like.save (err, _like) ->
          return callback 'your cant like the comment' if err
          Comment.findOneAndUpdate {tweet_id: like.comment_id}, {$inc: {like_count: 1}}, (err, comment) ->
            callback null

  auth: (auth_path='/auth') ->
    self = @
    return (req, res, next) ->
      url = urlparse(req.url)
      token = req.get('Authorization')
      token = if token and token.substr(0, 6) is 'Bearer' then token.substr(7) else false
      token = req.param('access_token') unless token
      now = new Date()

      if req.url.match(/^\/(js|css|img|favicon|logout)$/)
        next()
      else if req.session and req.session.user
        res.header 'P3P', "CP=\"CURa ADMa DEVa PSAo PSDoOUR BUS UNI PUR INT DEM STA PRE COM NAV OTC NOI DSP  COR\""
        req.user = util.clone req.session.user
        next()
      else if token
        OauthToken.findOne {access_token: token}, (err, token) ->
          if err or not token or token.created_at + token.expires_in * 1000 < now
            next()
          else
            self.get_user token.user_id, (err, user) ->
              req.user = user if user
              next()
      else
        return next() if url.pathname isnt auth_path
        type = req.param('type')
        body = req.body or {}
        res.header 'P3P', "CP=\"CURa ADMa DEVa PSAo PSDoOUR BUS UNI PUR INT DEM STA PRE COM NAV OTC NOI DSP  COR\""
        if type is 'refresh_token'
          OauthToken.findOne {refresh_token: body.refresh_token}, (err, token) ->
            return res.json {err: 403, msg: 'Token not found'} if err or not token
            if token.created_at + 60 * 24 * 3600 * 1000 < now
              token.remove (err) ->
                res.json {err: 403, msg: 'refresh_token expires'}
            else
              token.access_token = uuid()
              token.save (err, token) ->
                res.json token.toJSON()
        else
          self.do_auth body.username, body.passwd, (err, user) ->
            return res.json {err: 403, msg: '用户名或密码错误'} if err or not user
            if type is 'access_token'
              token = new OauthToken {
                user_id: user.user_id
                access_token: uuid()
                refresh_token: uuid()
                expires_in: 7 * 24 * 3600
              }

              token.save (err, token) ->
                return res.json {err: 403, msg: '用户名或密码错误'} if err
                res.json token.toJSON()
            else
              req.session.user = user
              res.json user

  do_auth: (username, passwd, callback) ->
    self = @
    User.findOne {username: username}, 'user_id', (err, user) ->
      return callback 'User not found' unless user
      Passwd.findOne {user_id: user.user_id}, 'passwd', (err, pwd) ->
        return callback 'passwd not found' unless pwd
        hash = hashed_password passwd
        return callback 'passwd not match' if hash isnt pwd.passwd
        self.get_user user.user_id, callback

  require_login: () ->
    return (req, res, next) ->
      return next() if req.user
      res.json {err: 401, msg: 'Unauthorized'}

  require_admin: () ->
    return (req, res, next) ->
      return next() if req.user and ~req.user.roles.indexOf('admin')
      res.json {err: 401, msg: 'Unauthorized'}

  favorite: (fav, callback) ->
    Favorite.findOne fav, (err, _fav) ->
      return callback 'your already favorite it' if _fav
      _fav = new Favorite fav
      _fav.save (err, _fav) ->
        callback err

  get_favorites: (query, options, callback) ->
    self = @
    Favorite.find query, null, options, (err, favs) ->
      return callback 'not favorite found' if err or favs.length is 0
      tweet_ids = favs.map (fav) ->
        return fav.tweet_id

      self.get_tweets tweet_id: {$in: tweet_ids}, null, callback

  upload: (file, bucket, callback) ->
    cb = (err, data) ->
      fs.unlink file.path, (e) ->
        callback err, data
    self = @
    File.findOne {file_key: file.hash}, (err, _file) ->
      return cb null, _file.toJSON() if _file
      fs.readFile file.path, (err, data) ->
        return cb err if err
        self.upyun.uploadFile "/#{bucket}/#{file.hash}", data, (err, status, data) ->
          return cb err if err
          return cb data if status isnt 200
          _file = new File {
            file_key: file.hash
            file_bucket: bucket
          }
          _file.save (err, _file) ->
            return cb err if err
            cb null, _file.toJSON()

  avatar_upload: (file, user_id, callback) ->
    @upload file, 'avatar', (err, data) ->
      return callback err if err
      return callback 'set avatar fail' unless data
      User.findOneAndUpdate {user_id: user_id}, {avatar: JSON.stringify(data)}, (err, user) ->
        return callback 'set avatar fail' if err
        callback null, data

  save_channel: (channel, callback) ->
    if channel.channel_id
      Channel.findOne channel_id: channel.channel_id, (err, chan) ->
        return callback 'channel is not found' unless chan
        Channel.find $or: [{urlname: channel.urlname}, {title: channel.title}], (err, chans) ->
          chans = chans.filter (_chan) ->
            return _chan and _chan.channel_id isnt chan.channel_id
          return callback 'urlname and title is already used' if chans.length is 2
          if chans.length is 1
            return callback 'urlname is already used' if chans[0].urlname is channel.urlname
            return callback 'title is already used' if chans[0].title is channel.title
          chan.urlname = channel.urlname
          chan.title = channel.title
          chan.save callback
    else
      Channel.find $or: [{urlname: channel.urlname}, {title:channel.title}], (err, chans) ->
        return callback 'urlname and title is already used' if chans.length is 2
        if chans.length is 1
          return callback 'urlname is already used' if chans[0].urlname is channel.urlname
          return callback 'title is already used' if chans[0].title is channel.title
        chan = new Channel channel
        chan.save callback

  get_channel_tweets: (query, options, callback) ->
    self = @
    Channel.findOne query, (err, channel) ->
      return callback 'channel not exists' unless channel
      ChannelTweet.find channel_id: channel.channel_id, null, options, (err, channel_tweets) ->
        return callback 'not channel tweets found' if err or channel_tweets.length is 0
        tweet_ids = channel_tweets.map (ctweet) ->
          return ctweet.tweet_id

        self.get_tweets tweet_id: {$in: tweet_ids}, null, (err, tweets) ->
          channel = channel.toJSON()
          tweet_seqs = {}
          channel_tweets.forEach (ct) ->
            tweet_seqs[ct.tweet_id] = ct.seq

          channel.tweets = tweets.map (tweet) ->
            tweet.seq = tweet_seqs[tweet.tweet_id]
            return tweet
          callback null, channel

  add_channel_tweet: (ctweet, callback) ->
    ChannelTweet.findOne ctweet, (err, _ctweet) ->
      return callback 'your already add it' if _ctweet
      _ctweet = new ChannelTweet ctweet
      Sequence.next "channel:#{ctweet.channel_id}", (seq) ->
        _ctweet.seq = seq
        _ctweet.save (err, _ctweet) ->
          callback err

  remove_channel_tweet: (ctweet, callback) ->
    ChannelTweet.findOne ctweet, (err, _ctweet) ->
      return callback 'ChannelTweet not found' unless _ctweet
      ctweet.remove (err) ->
        callback err

  unread: (query, callback) ->
    return callback 'seq not found' unless query.seq
    seq = Number query.seq
    if query.channel_id
      ChannelTweet.count {channel_id: query.channel_id, seq: {$gt: seq}}, (err, count) ->
        callback err, count

    else
      Tweet.count {tweet_id: {$gt: seq}}, (err, count) ->
        callback err, count

  set_view: (view, callback) ->
    UserView.findOneAndUpdate {channel_id: view.channel_id, user_id: view.user_id}
    , {last_seq: view.last_seq}, {new: true}, (err, _view) ->
      return callback err if err
      return callback null, _view.toJSON() if _view
      _view = new UserView view
      _view.save (err, _view) ->
        return callback err if err
        callback null, _view.toJSON()

  get_view: (view, callback) ->
    UserView.findOne {channel_id: view.channel_id, user_id: view.user_id}, (err, _view) ->
      return callback err if err
      return callback null, _view.toJSON() if _view
      callback 'view not found'

module.exports = Yabby
