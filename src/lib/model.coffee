mongoose = require 'mongoose'
Schema = mongoose.Schema

User = new Schema
  username: {type: String, index: {unique: true}}
  avatar: String
  tweet_count: {type: Number, default: 0}
  comment_count: {type: Number, default: 0}
  created_at: {type: Date, default: Date.now}

Passwd = new Schema
  user_id: {type: Schema.ObjectId, index: {unique: true}}
  email: {type: String, index: {unique: True}}
  passwd: String

OauthToken = new Schema
  user_id: Schema.ObjectId
  access_token: {type: String, index: {unique: true}}
  refresh_token: {type: String, index: {unique: true}}
  created_at: {type: Date, default: Date.now}
  expires_in: {type: Number, default: 3600 * 24 * 7}

Tweet = new Schema
  user_id: Schema.ObjectId
  text: String
  file_id: Schema.ObjectId
  comment_count: {type: Number, default: 0}
  like_count: {type: Number, default: 0}
  unlike_count: {type: Number, default: 0}
  created_at: {type: Date, default: Date.now}

Comment = new Schema
  tweet_id: {type: Schema.ObjectId, index: true}
  user_id: Schema.ObjectId
  text: String
  like_count: {type: Number, default: 0}
  created_at: {type: Date, default: Date.now}

File = new Schema
  file_key: {type: String, index: {unique: true}}
  file_bucket: String
  extra: String

Like = new Schema
  user_id: Schema.ObjectId
  tweet_id: Schema.ObjectId
  is_like: {type: Boolean, default: true}
  created_at: {type: Date, default: Date.now}

CommentLike = new Schema
  user_id: Schema.ObjectId
  comment_id: Schema.ObjectId
  created_at: {type: Date, default: Date.now}

Favorite = new Schema
  user_id: Schema.ObjectId
  tweet_id: Schema.ObjectId
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
