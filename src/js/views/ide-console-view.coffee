App.IdeConsoleView = Em.View.extend App.IdeTabViewMixin,
  templateName: 'ide/console'
  elementId: 'ide-console-view'
  classNameBindings: ['controller.fullscreen:fullscreen', 'controller.minimized:minimized']

  didInsertElement: ->
    @_super()
    if App.get('container').metadata.noConsole
      @get('controller').set 'minimized', true
    else
      @get('controller').createTab()

    @$().bind('click', (evt) =>
      if evt.which == 2 # middle-click
        @send('didClickClose', @get('content'))
        false
    )

  actions:
    didClickMinimizeConsole: ->
      if mainMenuController = App.get 'router.ideMainMenuController'
        mainMenuController.windowToggleMinimizeConsole()

    didClickFullScreen: ->
      if mainMenuController = App.get 'router.ideMainMenuController'
        mainMenuController.windowToggleFullScreenConsole()
