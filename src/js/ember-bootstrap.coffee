window.EmberENV =
  FEATURES:
    'query-params-new': true

require './fake_json/config'

Em = Ember
window.NitrousIO = Em.Application.extend Em.Evented,
  rootElement: '#app'

  platform:
    if navigator.platform.indexOf('Linux') != -1
      'linux'
    else if navigator.platform.indexOf('Windows') != -1
      'windows'
    else 'mac'

  chromeApp: false

  online: if !Em.isNone(window.navigator.onLine) then window.navigator.onLine else true
  offline: Em.computed.not 'online'

  settings: null

  config: null

  flashMessage: null

  slug: null

  user: null
  userSettings: null
  container: null
  hostBinding: Em.Binding.oneWay 'container.host'

  eventsSocket: null
  pingerSocket: null
  pinger: null

  terminalJsPath: null
  terminalCssPath: null

  consoleFocused: false
  consoleFullscreen: false
  consoleMinimized: false
  fileTreeHidden: false

  redirecting: false

  freighterdFeatures: null

  reloadContainer: ->
    @loadContainer(@get 'slug').then (container) ->
      container.loadCollaborators()
      container.loadHost()

  loadContainer: (slug)->
    if !slug
      return Em.RSVP.Promise.reject(new Error('No slug specified'))

    App.set 'slug', slug
    App.Container.fetch(slug).then (container) ->
      App.set 'container', container
      container

  didChangeTitle: (->
    title = @get 'title'
    document.title = if title
      "#{title} · Nitrous"
    else
      "Nitrous"
  ).observes 'title'

  didChangeSlug: (->
    slug = App.get 'slug'
    App.set 'title', "#{slug} · IDE"
  ).observes 'slug'

window.App = NitrousIO.create
  token: window.localStorage.getItem('token')

window.Lib = Ember.Namespace.create()

App.on 'load', ->
  App.set 'snackbar', App.Snackbar.create()

Em.TextSupport.reopen
  attributeBindings: ['readonly']

# HACK: silence bindAttr deprecation warning (bindAttrs are rendered by Hamlbars).
# Goes away when we can upgrade Hamlbars to 2.1+ or switch to HTMLbars/Emblem.
Em.Handlebars.registerHelper('bindAttr', Ember.Handlebars.helpers['bind-attr'])

# prevent file drops on the document causing browser to navigate away
$(document).bind 'drop dragover', (e) ->
  e.preventDefault()

# prevent esc from disconnecting websocket connection in firefox
$(window).keydown (e) ->
  e.preventDefault() if e.keyCode == 27

$(window).on 'offline', ->
  window.App?.set? 'online', false

$(window).on 'online', ->
  window.App?.set? 'online', true

$(window).on 'storage', (e) ->
  origEvent = e.originalEvent
  if origEvent.key == "token" && origEvent.newValue == null
    window.location.href = "/app/#/logout"
