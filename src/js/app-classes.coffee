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


#= require_tree ./mixins
#= require_tree ./lib
#= require ../lib/snackbar
#= require_tree ./models
#= require_tree ./view-models
#= require_tree ./controllers
#= require_tree ./views
#= require ../components/ui-connectivity-indicator-component
#= require ../components/ui-toggle-button-component
#= require ../views/snackbar-view
#= require_tree ./helpers
#= require_tree ../helpers
#= require_tree ./templates
#= require ../templates/components/ui-connectivity-indicator
#= require ../templates/components/ui-toggle-button
#= require ../templates/snackbar
#= require ../lib/event-message-handler
#= require ../lib/pinger-socket
#= require ./code-plugins/manager
#= require_tree ./code-plugins/plugins
#= require_tree ../shared
#= require_tree ./routes
#= require_self
#= require ./routes

# all classes except router are loaded
App.trigger 'load'
require "./routes"
