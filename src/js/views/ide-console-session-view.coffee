require '../mixins/inject-terminal-iframe-mixin'

consoleSessionViewNextId = 0

App.IdeConsoleSessionView = Em.View.extend App.InjectTerminalIframeMixin,
  templateName: 'console-session'
  consoleSessionViewId: null
  consoleSession: null
  classNames: ['ide-console-session-view']
  classNameBindings: ['consoleSession.active:active']

  iframeInjected: false

  init: ->
    @set 'consoleSessionViewId', ++consoleSessionViewNextId
    @_super.apply this, arguments

  didInsertElement: ->
    @_super()
    $(window).on "orientationchange.ideConsoleSessionView#{@get 'consoleSessionViewId'}", _.bind(@didChangeOrientation, this)
    $(window).on "unload.#{@get('elementId')}", =>
      @disconnect()
      return # need to return void
    @injectIframe()

  willDestroyElement: ->
    @_super()
    @disconnect()
    $(window).off "orientationchange.ideConsoleSessionView#{@get 'consoleSessionViewId'}"
    $(window).off "unload.#{@get('elementId')}"

  focusDidChange: (->
    if focused = @get 'consoleSession.focused'
      if iframeWindow = @$('iframe')[0]?.contentWindow
        if activeDocument = App.get 'router.ideEditorController.activeTab'
          activeDocument.set 'focused', false
        iframeWindow.focus()
        iframeWindow.NitrousTerminal?.focus?()
  ).observes 'consoleSession.focused'

  opsSocketDidGetDisconnected: (->
    terminal = @get 'terminal'
    if App.get('router.ideController.opsSocketNotReady') && !terminal.closed
      terminal.close(true) # close, but permit reconnection
  ).observes 'App.router.ideController.opsSocketNotReady'

  didChangeOrientation: ->
    window.setTimeout(=>
      if iframe = @$('iframe')[0]
        iframe.style.width = $('body').width() + 'px';
        iframe.contentWindow?.App?.page?.term?.sizeToFit?()
        window.setTimeout(->
          iframe.style.width = '100%'
        , 10)
    , 800)

  disconnect: ->
    @$('iframe')[0]?.contentWindow?.NitrousTerminal?.destroy()

  injectIframe: ->
    return if @get 'iframeInjected'
    @set 'iframeInjected', true
    Em.run.scheduleOnce 'afterRender', this, ->
      controller = @get 'controller'
      consoleSession = @get 'consoleSession'

      @injectTerminalIframe (terminal) =>
        consoleSession.set 'terminal', terminal
        terminal.ide = true
        terminal.term.write 'Connecting...'
        terminal.willOpen = =>
          controller.makeUrlAndConnect(terminal)
        terminal.didBlur = =>
          consoleSession.set 'focused', false
        terminal.didChangeTitle = (title) =>
          consoleSession.set 'title', title
        # the following terminal.open() call is only to invoke willOpen()
        # it will be no-op since no URL is set
        # makeUrlConnect will then call terminal.open again after setting the URL.
        terminal.open()
