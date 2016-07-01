require '../vendor/polyfills'
require '../lib/socket/socket-connection'
require 'script!../vendor/term'

parentWindow = window.parent
parentWindow = null if parentWindow == window

isMac = navigator.userAgent.indexOf("Macintosh") != -1

chromeApp = parentWindow?.App?.get('chromeApp') || false

utf8Decoder = new window.TextDecoder('utf8')

utf8Decode = (data) ->
  utf8Decoder.decode(new DataView(data))

appendBuffer = (buffer1, buffer2) ->
  if !buffer1? || buffer1.byteLength == 0
    return buffer2
  tmp = new Uint8Array(buffer1.byteLength + buffer2.byteLength)
  tmp.set(new Uint8Array(buffer1), 0)
  tmp.set(new Uint8Array(buffer2), buffer1.byteLength)
  tmp.buffer

window.NitrousTerminal =
  term: null
  conn: null
  url: null
  closed: false
  firstConnect: true
  readonly: false
  binaryMode: false
  ide: false

  shellId: null

  resizeTimeout: null

  dataBuffer: null
  bufferTimeout: null

  init: ->
    @conn = conn = new SocketConnection()
    conn.onbeforeopen   = => @willOpen()
    conn.onopen    = (ev) => @didOpen(ev)
    conn.onmessage = (ev) => @didReceiveMessage(ev)
    conn.onerror   = (ev) => @didFail(ev)
    conn.onclose   = (ev) => @didClose(ev)

    @term = term = new Terminal(80, 25)
    term.open(document.body)
    term.sizeToFit()
    term.showCursor()

    term.originalKeyDown = @term.keyDown
    term.keyDown = (event) =>
      if @ide
        r = switch
          when @matchesFocusEditorKeybinding event
            @focusEditor event
          when @matchesFullscreenConsoleKeybinding event
            @toggleFullscreenConsole event
          when @matchesMinimizeConsoleKeybinding event
            @toggleMinimizeConsole event
          when @matchesNextTabKeybinding event
            @makeNextTabActive event
          when @matchesPreviousTabKeybinding event
            @makePreviousTabActive event
          when @matchesNewConsoleScreenKeybinding event
            @newTab event
          when @matchesCloseConsoleScreenKeybinding event
            @closeTab event
          when @matchesCtrlTabKeybinding event
            false
          when @matchesCtrlShiftTabKeybinding event
            false
          else
            true
        return false if !r
      term.originalKeyDown(event)

    term.on 'resize', (cols, rows) =>
      return if @conn.readyState != 1
      @conn.send "r|#{cols} #{rows}"

    term.on 'title', (title) =>
      @didChangeTitle(title)

    term.handler = (data) =>
      return if @readonly || @closed || @conn.readyState != 1
      @conn.send "d|#{data}"

    onresize = =>
      window.onresize = null
      return unless @term
      if @resizeTimeout
        window.clearTimeout(@resizeTimeout)
      @resizeTimeout = window.setTimeout(=>
        @resizeTimeout = null
        @term.sizeToFit()
      , 50)
      window.onresize = onresize
    onresize()

    window.onfocus = =>
      return unless @term
      Terminal.focus = @term
      @term.redrawCursor()
      parentWindow?.App?.set?('consoleFocused', true)

    window.onblur = =>
      return unless @term
      Terminal.focus = null
      @didBlur()
      @term.redrawCursor()
      parentWindow?.App?.set?('consoleFocused', false)

    document.addEventListener('copy', @handleCopy, false)

  open: (nobeforeopen) ->
    @conn.binaryMode = @binaryMode

    @conn.url = @url
    if @conn.url && @shellId
      @conn.url += "&shell_id=#{@shellId}"
    @conn.open(nobeforeopen)
    @conn.url = null

  retry: ->
    @conn.retry()

  destroy: ->
    @close()
    @term?.destroy()

  close: (retry=false) ->
    if !retry
      @conn?.send 'c|bye'
      @willOpen = null
    @conn?.close(retry)

  focus: ->
    window.focus()
    @term?.focus()

  willOpen: ->
    # override me

  didBlur: ->
    # override me

  didChangeTitle: (title) ->
    # override me

  clear: ->
    @term.write '\x1b[r\x1b[H\x1b[J'

  handleCopy: ->
    sel = window.getSelection?()
    range = sel.getRangeAt?(0)
    text = sel.toString?()
    tempEl = document.createElement('pre')
    # return if browser required features are missing
    return true unless sel && sel.selectAllChildren && sel.removeAllRanges && sel.addRange && range && text && tempEl.textContent?
    # make temp element invisible
    tempEl.style.whiteSpace = 'pre'
    tempEl.style.position = 'fixed'
    tempEl.style.left = '100%'
    tempEl.style.opacity = '0'
    # strip trailing whitespaces
    tempEl.textContent = text.replace(/\s+$/gm, '')
    document.body.appendChild(tempEl)
    sel.selectAllChildren(tempEl)
    window.setTimeout(->
      tempEl.parentNode.removeChild(tempEl)
      sel.removeAllRanges()
      sel.addRange(range)
    , 10)
    true

  handleData: (data) ->
    window.clearTimeout(@bufferTimeout)
    @dataBuffer = appendBuffer(@dataBuffer, data)
    decoded = utf8Decode(@dataBuffer)

    flush = =>
      @dataBuffer = new ArrayBuffer(0)
      @term.write(decoded)

    # if invalid utf8 char is detected, buffer with timeout
    if decoded.length > 0 && decoded[decoded.length - 1] == "\uFFFD"
      @bufferTimeout = window.setTimeout(=>
        flush()
        @bufferTimeout = null
      , 200)
      return

    flush()

  didOpen: (ev) ->
    @closed = false
    @term.sizeToFit()
    if @firstConnect
      @firstConnect = false
      @clear()

  didReceiveMessage: (ev) ->
    type = ev.data.slice(0, 2)
    switch type
      when 'i|'
        newShellId = if @binaryMode
          utf8Decode(ev.binaryData.slice(2))
        else
          ev.data.slice(2)
        if @shellId && @shellId != newShellId
          @term.write "\r\n[Connection timed out]\r\n"
        @shellId = newShellId
      when 'd|'
        if @binaryMode
          @handleData(ev.binaryData.slice(2))
        else
          @term.write(ev.data.slice(2))
      when 'c|'
        @close()

  didFail: (ev) ->

  didClose: (ev) ->
    @closed = true
    if @conn?.ws._noRetry
      @term?.write("\r\n[Session closed]")

  focusEditor: (ev) ->
    return true unless parentWindow?.App?.get
    Terminal.cancel(ev)
    parentWindow.App.get('router.ideMainMenuController')?.windowFocusEditor()
    false

  toggleFullscreenConsole: (ev) ->
    return true unless parentWindow?.App?.get
    Terminal.cancel(ev)
    parentWindow.App.get('router.ideMainMenuController')?.windowToggleFullScreenConsole()
    false

  toggleMinimizeConsole: (ev) ->
    return true unless parentWindow?.App?.get
    Terminal.cancel(ev)
    parentWindow.App.get('router.ideMainMenuController')?.windowToggleMinimizeConsole()
    false

  makeNextTabActive: (ev) ->
    return true unless parentWindow?.App?.get
    Terminal.cancel(ev)
    parentWindow.App.get('router.ideMainMenuController')?.windowSelectNextTab()
    false

  makePreviousTabActive: (ev) ->
    return true unless parentWindow?.App?.get
    Terminal.cancel(ev)
    parentWindow.App.get('router.ideMainMenuController')?.windowSelectPreviousTab()
    false

  newTab: (ev) ->
    return true unless parentWindow?.App?.get
    Terminal.cancel(ev)
    parentWindow.App.get('router.ideMainMenuController')?.fileNew()
    false

  closeTab: (ev) ->
    return true unless parentWindow?.App?.get
    Terminal.cancel(ev)
    parentWindow.App.get('router.ideMainMenuController')?.fileClose()
    false

  matchesFocusEditorKeybinding: (event) ->
    (isMac && event.shiftKey && event.ctrlKey && event.keyCode == 67) || # mac: shift+ctrl+c
    (!isMac && event.ctrlKey && event.altKey && event.keyCode == 67)  || # pc:  ctrl+alt+c
    (chromeApp && isMac && event.metaKey && event.keyCode == 84)  || # mac chrome app: command+t
    (chromeApp && !isMac && event.shiftKey && event.ctrlKey && event.keyCode == 84) # pc chrome app: shift+ctrl+t

  matchesFullscreenConsoleKeybinding: (event) ->
    (event.keyCode == 70 && (
      (isMac && event.shiftKey && event.ctrlKey) || # mac: shift+ctrl+f
      (!isMac && event.ctrlKey && event.altKey)     # pc:  ctrl+alt+f
    ))

  matchesMinimizeConsoleKeybinding: (event) ->
    (event.keyCode == 77 && (
      (isMac && event.shiftKey && event.ctrlKey) || # mac: shift+ctrl+m
      (!isMac && event.ctrlKey && event.altKey)     # pc:  ctrl+alt+m
    ))

  matchesNextTabKeybinding: (event) ->
    (!chromeApp && event.shiftKey && event.ctrlKey && event.keyCode == 221) ||      # mac/pc: shift+ctrl+]
    (chromeApp && !event.shiftKey && event.ctrlKey && event.keyCode == 9) ||        # mac/pc chrome app: ctrl+tab
    (chromeApp && isMac && event.shiftKey && event.metaKey && event.keyCode == 221) # mac chrome app: shift+command+]

  matchesPreviousTabKeybinding: (event) ->
    (!chromeApp && event.shiftKey && event.ctrlKey && event.keyCode == 219) ||      # mac/pc: shift+ctrl+[
    (chromeApp && event.shiftKey && event.ctrlKey && event.keyCode == 9) ||         # mac/pc chrome app: shift+ctrl+tab
    (chromeApp && isMac && event.shiftKey && event.metaKey && event.keyCode == 219) # mac chrome app: shift+command+[

  matchesNewConsoleScreenKeybinding: (event) ->
    (event.keyCode == 78 && (
      (isMac && event.shiftKey && event.ctrlKey) || # mac: shift+ctrl+n
      (!isMac && event.ctrlKey && event.altKey)  || # pc:  ctrl+alt+n
      (chromeApp && isMac && event.metaKey)      || # mac chrome app: command+n
      (chromeApp && !isMac && event.shiftKey && event.ctrlKey) # pc chrome app: shift+ctrl+n
    ))

  matchesCloseConsoleScreenKeybinding: (event) ->
    (event.keyCode == 87 && (
      (isMac && event.shiftKey && event.ctrlKey) || # mac: shift+ctrl+w
      (!isMac && event.ctrlKey && event.altKey)  || # pc:  ctrl+alt+w
      (chromeApp && isMac && event.metaKey)      || # mac chrome app: command+w
      (chromeApp && !isMac && event.shiftKey && event.ctrlKey) # pc chrome app: shift+ctrl+w
    ))

  # keybinding ctrl+tab
  matchesCtrlTabKeybinding: (event) ->
    event.ctrlKey && event.keyCode == 9

  # keybinding ctrl+shift+tab
  matchesCtrlShiftTabKeybinding: (event) ->
    event.ctrlKey && event.shiftKey && event.keyCode == 9

window.webFontLoaded = ->
  NitrousTerminal.term?.sizeToFit()
