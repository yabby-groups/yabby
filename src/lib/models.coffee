mongoose = require 'mongoose'
Schema = mongoose.Schema
autoIncrement = require 'mongoose-auto-increment'
autoIncrement.initialize mongoose.connection

User = new Schema
  username: {type: String, index: {unique: true}}
  avatar: String
  tweet_count: {type: Number, default: 0}
  comment_count: {type: Number, default: 0}
  created_at: {type: Date, default: Date.now}

User.plugin autoIncrement.plugin, {model: 'User', field: 'user_id'}

Passwd = new Schema
  user_id: {type: Number, index: {unique: true}}
  email: {type: String, index: {unique: true}}
  passwd: String

OauthToken = new Schema
  user_id: Number
  access_token: {type: String, index: {unique: true}}
  refresh_token: {type: String, index: {unique: true}}
  created_at: {type: Date, default: Date.now}
  expires_in: {type: Number, default: 3600 * 24 * 7}

Tweet = new Schema
  user_id: Number
  text: String
  file_id: Number
  comment_count: {type: Number, default: 0}
  like_count: {type: Number, default: 0}
  unlike_count: {type: Number, default: 0}
  created_at: {type: Date, default: Date.now}

Tweet.plugin autoIncrement.plugin, {model: 'Tweet', field: 'tweet_id'}

Comment = new Schema
  tweet_id: {type: Number, index: true}
  user_id: Number
  text: String
  like_count: {type: Number, default: 0}
  created_at: {type: Date, default: Date.now}

Comment.plugin autoIncrement.plugin, {model: 'Comment', field: 'comment_id'}

File = new Schema
  file_key: {type: String, index: {unique: true}}
  file_bucket: String
  extra: String

File.plugin autoIncrement.plugin, {model: 'File', field: 'file_id'}

Like = new Schema
  user_id: Number
  tweet_id: Number
  is_like: {type: Boolean, default: true}
  created_at: {type: Date, default: Date.now}

CommentLike = new Schema
  user_id: Number
  comment_id: Number
  created_at: {type: Date, default: Date.now}

Favorite = new Schema
  user_id: Number
  tweet_id: Number
  created_at: {type: Date, default: Date.now}

exports.User = mongoose.model 'User', User
exports.Passwd = mongoose.model 'Passwd', Passwd
exports.OauthToken = mongoose.model 'OauthToken', OauthToken
exports.Tweet = mongoose.model 'Tweet', Tweet
exports.Comment = mongoose.model 'Comment', Comment
exports.File = mongoose.model 'File', File
exports.Like = mongoose.model 'Like', Like
exports.CommentLike = mongoose.model 'CommentLike', CommentLike
exports.Favorite = mongoose.model 'Favorite', Favorite
