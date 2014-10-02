_ = require 'underscore'

omit = (data) ->
  return _.omit data, ["__v", "_id", "passwd", "email"]

clean_obj = exports.clean_obj = (obj) ->
  obj = omit obj
  obj.file = omit obj.file if obj.file
  obj.user = clean_obj obj.user if obj.user
  obj.tweet = clean_obj obj.tweet if obj.tweet
  if obj.tweets
      obj.tweets = _.map obj.tweets, (obj) ->
        obj = clean_obj obj
        return obj

  return obj

