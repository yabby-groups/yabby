{User, Passwd, OauthToken, Tweet, Comment, File, Like, CommentLike, Favorite,
  Channel, ChannelTweet, Sequence, UserView, Binding} = require './lib/models'

async = require 'async'

util = require 'underscore'

omit = (data) ->
  return util.omit data, ["__v", "_id", "passwd", "email"]

clean_obj = (obj) ->
  obj = omit obj
  obj.file = omit obj.file if obj.file
  obj.user = clean_obj obj.user if obj.user
  return obj


module.exports = (app, yabby) ->
  require_login = yabby.require_login
  require_admin = yabby.require_admin

  index = (req, res) ->
    page = req.params.page or 1
    limit = if req.query.limit then Number(req.query.limit) else 10
    limit = 100 if limit > 100
    user = if req.user then JSON.stringify clean_obj(req.user) else null
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
