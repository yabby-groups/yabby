{User, Passwd, OauthToken, Tweet, Comment, File, Like, CommentLike, Favorite,
  Channel, ChannelTweet, Sequence, UserView, Binding} = require './lib/models'

async = require 'async'

module.exports = (app, yabby) ->
  require_login = yabby.require_login
  require_admin = yabby.require_admin

  app.get '/', (req, res) ->
    Tweet.count (err, total) ->
      res.render 'index', {
        current: 1
        total: total
        path: '/api/tweets/'
      }
