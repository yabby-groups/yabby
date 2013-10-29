mongoose = require 'mongoose'
{User, Passwd, OauthToken, Tweet, Comment, File, Like, CommentLike, Favorite} = require './model'
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
          user_id: u.id
          email: user.email
          passwd: hash
        }
        pwd.save next
    ], (err, result) ->
      return callback err if err
      self.get_user result.user_id, callback


module.exports = Yabby
