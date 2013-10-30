api_prefix = require("./config").api_prefix

module.exports = (app, yabby) ->
  send_json_response = (res, err, data) ->
    if err
      res.json({error: err})
    else
      res.json(data)

  app.get "#{api_prefix}/users/me", (req, res) ->
    send_json_response res, null, req.user

  app.post "#{api_prefix}/users/register", (req, res) ->
    user = req.body
    yabby.create_user user, (err) ->
      send_json_response res, err, {}

  app.post "#{api_prefix}/tweets/", (req, res) ->
    tweet = req.body
    tweet.user_id = req.user.user_id
    yabby.create_tweet tweet, (err, data) ->
      send_json_response res, err, data

  app.get "#{api_prefix}/tweets/:tweet_id", (req, res) ->
    tweet_id = req.params.tweet_id
    yabby.get_tweet tweet_id, (err, data) ->
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
