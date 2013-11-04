
#  Module dependencies.

express = require 'express'
http = require 'http'
path = require 'path'

Yabby = require './lib/yabby'
MongoStore = require('connect-mongo')(express)

config = require './config'

yabby = new Yabby(config)

app = express()

# all environments
app.set 'port', process.env.PORT or 3000
app.set 'views', path.join(__dirname, 'views')
app.set 'view engine', 'jade'
app.use express.favicon()
app.use express.logger('dev')
app.use express.urlencoded()
app.use express.json()
app.use express.methodOverride()
app.use express.cookieParser()
app.use express.session {
  secret: config.cookie_secret,
  store: new MongoStore({url: config.mongod})
}
app.use yabby.auth()
app.use app.router
app.use express.static(path.join(__dirname, 'public'))

# app.all '*', (req, res, next) ->
#   res.header("Access-Control-Allow-Origin", "*")
#   res.header("Access-Control-Allow-Headers", "X-Requested-With")
#   res.header("Access-Control-Allow-Methods","PUT,POST,GET,DELETE,OPTIONS")
#   res.header("X-Powered-By",' 3.2.1')
#   res.header("Content-Type", "application/json;charset=utf-8")
#   next()

# development only
if 'development' is app.get('env')
  app.use express.errorHandler()

require('./api')(app, yabby)

http.createServer(app).listen app.get('port'), () ->
  console.log "Express server listening on port #{app.get('port')}"
