{services, host} = require '../config'
qs = require 'querystring'
minreq = require 'minreq'
{Binding} = require './models'
redirect_uri = "http://#{host}/oauth/callback/"

exports.route = (app) ->
  app.get '/oauth/:type', exports.oauth
  app.get '/oauth/callback/:type', exports.callback
  app.get '/signin', exports.signin
  app.get '/signup', exports.signup

exports.oauth = (req, res)->
  type = req.params.type
  next = req.query.next or '/signup'
  req.session.next = next

  if type is 'weibo'
    url = 'https://api.weibo.com/oauth2/authorize?' + qs.stringify {
      client_id: services.weibo.appkey
      response_type: 'code'
      redirect_uri: "#{redirect_uri}weibo"
    }

  else if type is 'tqq'

  else if type is 'qzone'
    url = ' https://graph.qq.com/oauth2.0/authorize?' + qs.stringify {
      client_id: services.qzone.appkey
      response_type: 'code'
      redirect_uri: "#{redirect_uri}qzone"
      state: 'test'
      scope: "get_user_info,get_other_info"
    }
  else if type is 'renren'
    url = 'https://graph.renren.com/oauth/authorize?' + qs.stringify {
      client_id: services.renren.appkey
      response_type: 'code'
      redirect_uri: "#{redirect_uri}renren"
    }
  else if type is 'douban'
    url = 'https://www.douban.com/service/auth2/auth?' + qs.stringify {
      client_id: services.douban.appkey
      response_type: 'code'
      redirect_uri: "#{redirect_uri}douban"
      state: 'test'
    }

  res.writeHead 302, Location: url
  res.end()

exports.callback = (req, res)->
  method = 'post'
  code = req.query.code
  type = req.params.type
  next = req.session.next
  delete req.session.next

  if type is 'weibo'
    url = 'https://api.weibo.com/oauth2/access_token?' + qs.stringify {
      client_id: services.weibo.appkey
      client_secret: services.weibo.secret
      grant_type: 'authorization_code'
      redirect_uri: "#{redirect_uri}weibo"
      code: code
    }
  else if type is 'tqq'

  else if type is 'qzone'
    url = 'https://graph.qq.com/oauth2.0/token?' + qs.stringify {
      client_id: services.qzone.appkey
      client_secret: services.qzone.secret
      grant_type: 'authorization_code'
      redirect_uri: "#{redirect_uri}qzone"
      code: code
    }
    method = 'get'
  else if type is 'renren'
    url = 'https://graph.renren.com/oauth/token?' + qs.stringify {
      client_id: services.renren.appkey
      client_secret: services.renren.secret
      grant_type: 'authorization_code'
      redirect_uri: "#{redirect_uri}renren"
      code: code
    }
  else if type is 'douban'
    body =
      client_id: services.douban.appkey
      client_secret: services.douban.secret
      grant_type: 'authorization_code'
      redirect_uri: "#{redirect_uri}douban"
      code: code
    url = 'https://www.douban.com/service/auth2/token'
  minreq {
    uri:url
    method: method
    'content-type': 'application/x-www-form-urlencoded'
    form: body
  }, (err, resp, body)->
    return res.json error: err if err
    try
      if type is 'qzone'
        rsp = qs.parse body
      else
        rsp = JSON.parse body

      req.session.token =
        token: rsp
        type: type

      res.writeHead 302, Location: "#{next}"
      res.end()
    catch e
      res.json {error: e, data: body}

exports.signin = (req, res) ->
  token = req.session.token
  delete req.session.token
  type = token.type
  token = token.token
  if type is "weibo"
    weibo_signin token, (err, data) ->
      if err
        res.json {err: 401, msg: err}
      else
        res.json data
  else
    res.json {err: 401, msg: 'not support'}

exports.signup = (req, res) ->
  token = req.session.token
  delete req.session.token
  type = token.type
  token = token.token
  if type is "weibo"
    weibo_signup token, (err, data) ->
      if err
        res.json {err: 401, msg: err}
      else
        res.json data
  else
    res.json {err: 401, msg: 'not support'}

weibo_signin = (token, callback) ->
  url = 'https://api.weibo.com/2/users/show.json?' + qs.stringify({
    access_token: token.access_token
    uid: token.uid
  })
  type = 'weibo'
  minreq url, (err, resp, body) ->
    return callback err if err
    try
      rsp = JSON.parse body
      return callback rsp.err if rsp.err
      delete rsp.status
      binding = {}
      binding.nickname = rsp.screen_name
      binding.sex = rsp.sex
      binding.domain = rsp.domain
      binding.token = token.access_token
      binding.raw = rsp
      binding.token_raw = token
      binding.uid = token.uid
      binding.expire_at = Number(token.expires_in)*1000 + new Date()
      binding.username = rsp.name
      binding.type = type
      Binding.findOne {type: type, uid: binding.uid}, (err, bind) ->
        return callback err if err
        return callback null, {err: 401, \
          msg: "your are aleardy bind", user_id: bind.user_id} if bind
        User.findOne username: binding.username, (err, u) ->
          return callback err if err
          user =
            username: binding.username
            avatar: null
          user.username += 'a' if u
          user = new User user
          user.save (err, user) ->
            return callback err if err
            binding.user_id = user.user_id
            bind = new Binding binding
            bind.save (err, bind) ->
              return callback err if err
              callback null, user.toJSON()
    catch e
      callback e

weibo_signup = (token, callback) ->
  Binding.findOne {type: 'weibo', uid: token.uid}, (err, bind) ->
  return callback err if err
  bind.token = token.access_token
  bind.expire_at = Number(token.expires_in)*1000 + new Date()
  bind.token_raw = token
  bind.save (err, bind) ->
    return callback err if err
    User.findOne user_id: bind.user_id, (err, user) ->
      return callback 'User not found' unless user
      user = user.toJSON()
      user.avatar = JSON.parse(user.avatar) if user.avatar
      callback null, user
