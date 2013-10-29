
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
app.use express.bodyParser()
app.use express.methodOverride()
app.use express.cookieParser()
app.use express.session {
  secret: 'maskdfnlaf',
  store: new MongoStore({url: config.mongod})
}
app.use app.router
app.use express.static(path.join(__dirname, 'public'))

# development only
if 'development' is app.get('env')
  app.use express.errorHandler()

require('./api')(app, yabby)

http.createServer(app).listen app.get('port'), () ->
  console.log "Express server listening on port #{app.get('port')}"
