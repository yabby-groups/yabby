{User, Passwd, OauthToken, Tweet, Comment, File, Like, CommentLike, Favorite,
  Channel, ChannelTweet, Sequence, UserView, Binding} = require './models'

async = require 'async'

module.exports = (app, yabby) ->
  require_login = yabby.require_login
  require_admin = yabby.require_admin

  app.get '/', (req, res) ->
    res.render 'index'
