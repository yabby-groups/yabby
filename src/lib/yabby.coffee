mongoose = require 'mongoose'
{User, Passwd, OauthToken, Tweet, Comment, File, Like, CommentLike, Favorite} = require './models'
async = require 'async'
crypto = require 'crypto'

class Yabby
  constructor: (@config) ->
    mongoose.connect @config.mongod

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
        u.save next
      (u, next) ->
        shasum = crypto.createHash 'sha1'
        shasum.update user.passwd
        hash = shasum.digest 'hex'
        pwd = new Passwd {
          user_id: u.user_id
          email: user.email
          passwd: hash
        }
        pwd.save next
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
    Tweet.findOneAndRemove tweet, callback

  get_tweets: (query, options, callback) ->
    Tweet.find query, null, options, (err, tweets) ->
      return callback 'there if not tweets' if err
      return callback null, null unless tweets
      async.parallel {
        users: (next) ->
          user_ids = tweets.map (tweet) ->
            return tweet.user_id

          User.find {user_id: user_ids}, (err, users) ->
            ret = {}
            users.forEach users, (user) ->
              user = user.toJSON()
              user.avatar = JSON.parse(user.avatar) if user.avatar
              ret[user_id] = user
            next null, ret
        files: (next) ->
          file_ids = tweets.map (tweet) ->
            return tweet.file_id
          file_ids = file_ids.filter (file_id) ->
            return file_id
          File.find file_id: file_ids, (err, files) ->
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
      return callback 'not comments' if err or not comments
      user_ids = comments.map (comment) ->
        return comment.user_id

      User.find {user_id: user_ids}, (err, users) ->
        _users = {}
        users.forEach (user) ->
          user = user.toJSON()
          user.avatar = JSON.parse(user.avatar) if user.avatar
          _users[user.user_id] = user

        comments = comments.map (comment) ->
          comment = comment.toJSON()
          comment.user = _users[comment.user_id]

        callback null, comments

module.exports = Yabby
