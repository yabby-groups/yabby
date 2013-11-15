api_prefix = require("./config").api_prefix
formidable = require 'formidable'

module.exports = (app, yabby) ->
  require_login = yabby.require_login
  require_admin = yabby.require_admin

  send_json_response = (res, err, data) ->
    if err
      res.json {err: 401, msg: err}
    else
      data = {} unless data
      res.json data

  app.get "#{api_prefix}/users/me", require_login(), (req, res) ->
    send_json_response res, null, req.user

  app.post "#{api_prefix}/users/register", (req, res) ->
    user = req.body
    yabby.create_user user, (err) ->
      send_json_response res, err, {}

  app.post "#{api_prefix}/tweets/", require_login(), (req, res) ->
    tweet = req.body
    tweet.user_id = req.user.user_id
    yabby.create_tweet tweet, (err, data) ->
      send_json_response res, err, data

  app.get "#{api_prefix}/tweets/:tweet_id", (req, res) ->
    tweet_id = req.params.tweet_id
    yabby.get_tweet tweet_id, (err, data) ->
      send_json_response res, err, data

  app.delete "#{api_prefix}/tweets/:tweet_id", require_login(), (req, res) ->
    tweet_id = req.params.tweet_id
    user_id = req.user.user_id
    yabby.del_tweet {tweet_id: tweet_id, user_id: user_id}, (err, data) ->
      send_json_response res, err, data

  app.get "#{api_prefix}/tweets", (req, res) ->
    page = req.query.page
    page = if page then parseInt(page) else 0
    limit = req.query.limit
    limit = if limit then parseInt(limit) else 10
    limit = 50 if limit > 50
    skip = page * limit
    yabby.get_tweets null, {skip: skip, limit: limit, sort: {tweet_id: -1}}, (err, data) ->
      data = data or {}
      send_json_response res, err, data

  app.get "#{api_prefix}/users/:user_id/tweets", (req, res) ->
    user_id = req.params.user_id
    page = req.query.page
    page = if page then Number(page) else 0
    limit = req.query.limit
    limit = if limit then Number(limit) else 10
    limit = 50 if limit > 50
    skip = page * limit
    yabby.get_tweets {user_id: user_id}, {skip: skip, limit: limit, sort: {tweet_id: -1}}, (err, data) ->
      data = data or {}
      send_json_response res, err, data

  app.get "#{api_prefix}/tweets/:tweet_id/comments", (req, res) ->
    tweet_id = req.params.tweet_id
    page = req.query.page
    page = if page then Number(page) else 0
    limit = req.query.limit
    limit = if limit then Number(limit) else 10
    limit = 50 if limit > 50
    skip = page * limit
    yabby.get_comments tweet_id: tweet_id, {skip: skip, limit: limit, sort: {comment_id: -1}}, (err, data) ->
      send_json_response res, err, data

  app.post "#{api_prefix}/tweets/:tweet_id/comments", require_login(), (req, res) ->
    tweet_id = req.params.tweet_id
    comment = req.body
    comment.tweet_id = tweet_id
    comment.user_id = req.user.user_id
    yabby.create_comment comment, (err) ->
      send_json_response res, err, {}

  app.post "#{api_prefix}/tweets/:tweet_id/comments/:comment_id/like", require_login(), (req, res) ->
    tweet_id = req.params.tweet_id
    comment_id = req.params.comment_id
    like = {user_id:req.user.user_id, comment_id: comment_id}
    yabby.comment_like like, (err) ->
      send_json_response res, err, {}

  app.delete "#{api_prefix}/tweets/:tweet_id/comments/:comment_id", require_login(), (req, res) ->
    tweet_id = req.params.tweet_id
    comment_id = req.params.comment_id
    like = {user_id:req.user.user_id, comment_id: comment_id}
    comment = {tweet_id: tweet_id, comment_id: comment_id, user_id: req.user.user_id}
    yabby.del_comment comment, (err) ->
      send_json_response res, err, {}

  app.post "#{api_prefix}/tweets/:tweet_id/like", require_login(), (req, res) ->
    tweet_id = req.params.tweet_id
    like = {user_id:req.user.user_id, tweet_id: tweet_id, is_like: true}
    yabby.like like, (err) ->
      send_json_response res, err, {}

  app.post "#{api_prefix}/tweets/:tweet_id/unlike", require_login(), (req, res) ->
    tweet_id = req.params.tweet_id
    like = {user_id:req.user.user_id, tweet_id: tweet_id, is_like: false}
    yabby.like like, (err) ->
      send_json_response res, err, {}

  app.post "#{api_prefix}/tweets/:tweet_id/favorite", require_login(), (req, res) ->
    tweet_id = req.params.tweet_id
    fav = {user_id:req.user.user_id, tweet_id: tweet_id}
    yabby.favorite fav, (err) ->
      send_json_response res, err, {}

  app.get "#{api_prefix}/users/:user_id/favorite", require_login(), (req, res) ->
    user_id = req.params.user_id
    page = req.query.page
    page = if page then Number(page) else 0
    limit = req.query.limit
    limit = if limit then Number(limit) else 10
    limit = 50 if limit > 50
    skip = page * limit
    yabby.get_favorites {user_id: user_id}, {skip: skip, limit: limit, sort: {tweet_id: -1}}, (err, data) ->
      data = data or {}
      send_json_response res, err, data

  app.post "#{api_prefix}/upload", require_login(), (req, res) ->
    form = new formidable.IncomingForm()
    form.hash = 'sha1'
    form.parse req, (err,fields, files) ->
      return send_json_response res, 'please choose a file' unless files.file
      yabby.upload files.file, 'tweet', (err, data) ->
        send_json_response res, err, data

  app.post "#{api_prefix}/avatar_upload", require_login(), (req, res) ->
    form = new formidable.IncomingForm()
    form.hash = 'sha1'
    form.parse req, (err,fields, files) ->
      return send_json_response res, 'please choose file' unless files.file
      yabby.avatar_upload files.file, req.user.user_id, (err, data) ->
        send_json_response res, err, data

  app.get "#{api_prefix}/channel/:urlname_or_channel_id/tweets", (req, res) ->
    urlname_or_channel_id = req.params.urlname_or_channel_id
    page = req.query.page
    page = if page then Number(page) else 0
    limit = req.query.limit
    limit = if limit then Number(limit) else 10
    limit = 50 if limit > 50
    skip = page * limit
    options = {skip: skip, limit: limit, sort: {channel_id: -1}}
    query = {}
    if /^\d+$/.exec(urlname_or_channel_id)
      query.channel_id = Number(urlname_or_channel_id)
    else
      query.urlname = urlname_or_channel_id

    yabby.get_channel_tweets query, options, (err, ctweets) ->
      send_json_response res, err, ctweets

  app.get "#{api_prefix}/unread", (req, res) ->
    yabby.unread req.query, (err, count) ->
      send_json_response res, err, {unread: count}

  app.get "#{api_prefix}/users/view", require_login(), (req, res) ->
    view = {
      channel_id: req.param('channel_id'),
      user_id: req.user.user_id
    }
    yabby.get_view view, (err, data) ->
      send_json_response res, err, data

  app.post "#{api_prefix}/users/view", require_login(), (req, res) ->
    view = {
      channel_id: req.param('channel_id'),
      user_id: req.user.user_id,
      last_seq: req.param('last_seq')
    }
    yabby.set_view view, (err, data) ->
      send_json_response res, err, data

  app.post "#{api_prefix}/channel", require_admin(), (req, res) ->
    channel = req.body
    yabby.save_channel channel, (err, data) ->
      send_json_response res, err, data

  app.delete "#{api_prefix}/channel/:urlname_or_channel_id", require_admin(), (req, res) ->
    urlname_or_channel_id = req.params.urlname_or_channel_id
    channel = {}
    if /^\d+$/.exec(urlname_or_channel_id)
      channel.channel_id = Number(urlname_or_channel_id)
    else
      channel.urlname = urlname_or_channel_id
    yabby.del_channel channel, (err, data) ->
      send_json_response res, err, data

  app.post "#{api_prefix}/channel/:urlname_or_channel_id/tweets", require_admin(), (req, res) ->
    body = req.body || {}
    if not body.channel_id
      urlname_or_channel_id = req.params.urlname_or_channel_id
      if /^\d+$/.exec(urlname_or_channel_id)
        body.channel_id = Number(urlname_or_channel_id)

    return send_json_response res, 'Invalid params' if not body.channel_id or not body.tweet_id
    t =
      channel_id: body.channel_id
      tweet_id: body.tweet_id
    yabby.add_channel_tweet t, (err, data) ->
      send_json_response res, err, data
