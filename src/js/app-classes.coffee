require './backwards-compatibility'

req = require.context('./lib', true, /^(.*\.(coffee$|js$))[^.]*$/igm)
req(key) for key in req.keys()
req = require.context('./mixins', true, /^(.*\.(coffee$|js$))[^.]*$/igm)
req(key) for key in req.keys()
req = require.context('./models', true, /^(.*\.(coffee$|js$))[^.]*$/igm)
req(key) for key in req.keys()
req = require.context('./view-models', true, /^(.*\.(coffee$|js$))[^.]*$/igm)
req(key) for key in req.keys()
req = require.context('./controllers', true, /^(.*\.(coffee$|js$))[^.]*$/igm)
req(key) for key in req.keys()
req = require.context('./views', true, /^(.*\.(coffee$|js$))[^.]*$/igm)
req(key) for key in req.keys()
req = require.context('./components', true, /^(.*\.(coffee$|js$))[^.]*$/igm)
req(key) for key in req.keys()
req = require.context('./helpers', true, /^(.*\.(coffee$|js$))[^.]*$/igm)
req(key) for key in req.keys()
req = require.context('./templates', true, /^(.*\.(emblem$))[^.]*$/igm)
req(key) for key in req.keys()
req = require.context('./templates', true, /^(.*\.(hbs$))[^.]*$/igm)
req(key) for key in req.keys()
req = require.context('./code-plugins', true, /^(.*\.(coffee$|js$))[^.]*$/igm)
req(key) for key in req.keys()
req = require.context('./shared', true, /^(.*\.(coffee$|js$))[^.]*$/igm)
req(key) for key in req.keys()
req = require.context('./routes', true, /^(.*\.(coffee$|js$))[^.]*$/igm)
req(key) for key in req.keys()

# all classes except router are loaded
App.trigger 'load'
require "./routes"
