{User, Passwd, OauthToken, Tweet, Comment, File, Like, CommentLike, Favorite,
  Channel, ChannelTweet, Sequence, UserView, Binding} = require './lib/models'

{host} = require "./config"

{clean_obj} = require './lib/util'

async = require 'async'


module.exports = (app, yabby) ->
  require_login = yabby.require_login
  require_admin = yabby.require_admin

  index = (req, res) ->
    page = req.params.page or 1
    limit = if req.query.limit then Number(req.query.limit) else 10
    limit = 50 if limit > 50
    user = if req.user then clean_obj(req.user) else {}
    skip = (page - 1) * limit

    async.waterfall [
      (next) ->
        yabby.get_tweets null, {skip: skip, limit: limit, sort: {tweet_id: -1}}, next
      (tweets, next) ->
        tweets = tweets or []
        if req.user and req.user.user_id
          yabby.filled_favorite tweets, req.user.user_id, (err, tweets) ->
            next null, tweets
        else
          next null, tweets

    ], (err, tweets) ->
      obj = clean_obj tweets: tweets
      Tweet.count (err, total) ->
        res.render 'index', {
          current: page
          total: total
          limit: limit
          user: user
          api: '/api/tweets'
          url: "#{host}"
          tweets: obj.tweets
        }


  favorite = (req, res) ->
    page = req.params.page or 1
    limit = if req.query.limit then Number(req.query.limit) else 10
    limit = 50 if limit > 50
    user = if req.user then clean_obj(req.user) else {}
    skip = (page - 1) * limit
    yabby.get_favorites {user_id: user.user_id}, {skip: skip, limit: limit, sort: {tweet_id: -1}}, (err, data) ->
      data = data or {}
      data = clean_obj {tweets: data}
      Favorite.count {user_id: user.user_id}, (err, total) ->
        res.render 'favorite', {
          current: page
          total: total
          limit: limit
          user: user
          api: "/api/users/#{user.user_id}/favorite"
          url: "/favorite"
          tweets: data.tweets
        }

  user_tweets = (req, res) ->
    page = req.params.page or 1
    user_id = req.params.user_id
    limit = if req.query.limit then Number(req.query.limit) else 10
    limit = 50 if limit > 50
    user = if req.user then clean_obj(req.user) else {}
    skip = (page - 1) * limit
    async.waterfall [
      (next) ->
        yabby.get_tweets {user_id: user_id}, {skip: skip, limit: limit, sort: {tweet_id: -1}}, next
      (tweets, next) ->
        tweets = tweets or []
        if req.user and req.user.user_id
          yabby.filled_favorite tweets, req.user.user_id, (err, tweets) ->
            next null, tweets
        else
          next null, tweets

    ], (err, tweets) ->
      obj = clean_obj tweets: tweets
      Tweet.count {user_id: user_id}, (err, total) ->
        res.render 'user_tweet', {
          current: page
          total: total
          limit: limit
          user: user
          api: "/api/users/#{user_id}/tweets"
          url: "/users/#{user_id}"
          tweets: obj.tweets
        }


  app.get "/", index
  app.get "/p/:page", index

  app.get "/users/:user_id", user_tweets
  app.get "/users/:user_id/p/:page", user_tweets

  app.get "/favorite", require_login(), favorite
  app.get "/favorite/p/:page", require_login(), favorite

  app.get "/tweets/new", require_login(), (req, res) ->
    user = if req.user then clean_obj(req.user) else {}
    tweet_id = req.params.tweet_id
    res.render 'new_tweet', {
      user: user
      api: "/api/tweets"
      url: "/tweets/new"
    }

  app.get "/tweets/:tweet_id", (req, res) ->
    user = if req.user then clean_obj(req.user) else {}
    tweet_id = req.params.tweet_id

    async.waterfall [
      (next) ->
        yabby.get_tweet tweet_id, next
      (tweet, next) ->
        return next null, tweet unless req.user
        yabby.filled_favorite [tweet], req.user.user_id, (err, tweets) ->
          next null, tweets[0]

    ], (err, tweet)->
      tweet = tweet or {}
      tweet = clean_obj tweet
      res.render 'tweet', {
        user: user
        api: "/api/tweets/#{tweet_id}"
        url: "/tweets/#{tweet_id}"
        tweet: tweet
      }


  app.get "/logout", (req, res) ->
    if req.session and req.session.user
      delete req.session.user

    res.json {}


  app.get "/settings", require_login(), (req, res) ->
    user = if req.user then clean_obj(req.user) else {}
    res.render 'settings', {
      user: user
      api: "/api/users/me"
      url: "/settings"
    }
