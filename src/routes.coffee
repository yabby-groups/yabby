module.exports = (app, yabby) ->
  require_login = yabby.require_login
  require_admin = yabby.require_admin

  app.get '/', (req, res) ->
      res.render 'index'
