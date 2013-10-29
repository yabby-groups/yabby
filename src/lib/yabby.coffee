mongoose = require 'mongoose'
{User, Passwd, OauthToken, Tweet, Comment, File, Like, CommentLike, Favorite} = require './model'
async = require 'async'

class Yabby
  constructor: (@config) ->
    mongoose.connect @config.mongod


module.exports = Yabby
