{services, host} = require '../config'
qs = require 'querystring'
minreq = require 'minreq'
{Binding} = require './models'
redirect_uri = "http://#{host}/oauth/callback/"

exports.route = (app) ->
  app.get '/oauth/:type', exports.oauth
  app.get '/oauth/callback/:type', exports.callback

exports.oauth = (req, res)->
  type = req.params.type
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

      user = req.user
      Binding.findOne {type: type, user_id: user.user_id}, (err, token)->
        next_time = Number(rsp.expires_in) * 1000 + Date.now()
        if token
          token.token = rsp.access_token
          token.raw = body
          token.next_time = next_time
        else
          token = new Binding {
            token: rsp.access_token
            raw: body
            type: type
            next_time: next_time
            user_id: user.user_id
          }
        token.save -> res.json rsp
    catch e
      res.json {error: e, data: body}
