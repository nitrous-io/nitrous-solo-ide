App.IdeConsoleController = Em.ArrayController.extend App.IdeTabControllerMixin, App.TerminalConnectionMixin,
  needs: ['ideFileFinder']

  modelClass: App.ConsoleSession
  content: null
  fullscreenBinding: 'App.consoleFullscreen'
  minimizedBinding: 'App.consoleMinimized'

  initialize: ->
    @set 'content', []
    @set 'fullscreen', (App.localStorage.get('fullscreenConsole') ? false)

  fullscreenDidChange: (->
    App.localStorage.set 'fullscreenConsole', @get('fullscreen')
  ).observes 'fullscreen'

  reset: ->
    @set 'content', null

  makeUrlAndConnect: (terminal, session) ->
    return unless container = App.get('container')
    @makeUrl(container, terminal, 'shell').then (url) =>
      # continue to load the terminal
      terminal.url = url
      terminal.open(true)
      terminal.focus()

      if session.get('initCommand')
        @runCommand(terminal, session.get('initCommand'))

    , (jqxhr) ->
      terminal.retry()

  runCommand: (terminal, command) ->
    if terminal.conn.ws.readyState == 1
      terminal.conn.send("d|#{command} \n")
    else
      unless terminal.closed
        Ember.run.later( =>
          @runCommand(terminal, command)
        , 1000)

  addTab: (tab, settings = {}) ->
    empty = @get('content.length') == 0
    @_super.apply this, arguments
    if empty
      App.get('container').setMetadata({noConsole: null})
      @set 'minimized', false

  removeTab: (tab)->
    @_super.apply this, arguments
    if @get('content.length') == 0
      App.get('container').setMetadata({noConsole: true})
      unless @get 'fullscreen'
        @set 'minimized', true
