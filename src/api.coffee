api_prefix = require("./config").api_prefix

module.exports = (app, yabby) ->
    send_json_response = (res, err, data) ->
        if err
            res.json({error: err})
        else
            res.json(data)

    app.get "#{api_prefix}/users/me/", (req, res) ->
        send_json_response res, null, req.user
