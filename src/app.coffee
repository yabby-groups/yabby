
#  Module dependencies.

express = require 'express'
http = require 'http'
path = require 'path'
bodyParser = require 'body-parser'
methodOverride = require 'method-override'
cookieParser = require 'cookie-parser'
session = require 'express-session'
errorHandler = require 'errorhandler'
favicon = require 'serve-favicon'

Yabby = require './lib/yabby'
MongoStore = require('connect-mongo')(session)

config = require './config'

yabby = new Yabby(config)

app = express()

# all environments
app.set 'port', config.port or process.env.PORT or 3000
app.set 'host', config.host or process.env.HOST or '127.0.0.1'
app.set 'views', path.join(__dirname, 'views')
app.set 'view engine', 'jade'
app.use favicon(__dirname + '/public/favicon.ico')
# app.use express.logger('dev')
app.use bodyParser.urlencoded({ extended: false  })
app.use bodyParser.json()
app.use methodOverride()
app.use cookieParser()
app.use session {
  secret: config.cookie_secret,
  resave: true,
  saveUninitialized: true,
  store: new MongoStore({url: config.mongod})
}
app.use yabby.auth()
# app.use app.router
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
  app.use errorHandler()

require('./api')(app, yabby)
require('./lib/oauth')(app, yabby)
require('./routes')(app, yabby)

http.createServer(app).listen app.get('port'), () ->
  console.log "Express server listening on port #{app.get('port')}"
