{User, Passwd, OauthToken, Tweet, Comment, File, Like, CommentLike, Favorite,
  Channel, ChannelTweet, Sequence, UserView, Binding} = require './lib/models'

{clean_obj} = require './lib/util'

async = require 'async'


module.exports = (app, yabby) ->
  require_login = yabby.require_login
  require_admin = yabby.require_admin

  index = (req, res) ->
    page = req.params.page or 1
    limit = if req.query.limit then Number(req.query.limit) else 10
    limit = 100 if limit > 100
    user = if req.user then clean_obj(req.user) else {}
    Tweet.count (err, total) ->
      res.render 'index', {
        current: page
        total: total
        limit: limit
        user: user
        path: '/api/tweets/'
      }


  app.get "/", index
  app.get "/p/:page", index

  app.get "/logout", (req, res) ->
    if req.session and req.session.user
      delete req.session.user

    res.json {}
