utf8Encoder = new window.TextEncoder('utf8')
utf8Decoder = new window.TextDecoder('utf8')

utf8Encode = (data) ->
  utf8Encoder.encode(data)

utf8Decode = (data) ->
  utf8Decoder.decode(new DataView(data))

class window.SocketConnection
  ws: null
  url: undefined
  protocols: undefined
  shouldRetry: true
  retries: 0
  retryTimeout: null
  binaryMode: false

  heartbeatTimer: null
  heartbeatTimeout: 30000

  constructor: (url, protocols) ->
    @url = url
    @protocols = protocols
    @retries = 0

  open: (nobeforeopen) ->
    if @ws
      @close()

    unless nobeforeopen
      @onbeforeopen()

    if !@url
      @ws = null
      return

    @heartbeat()
    ws = @ws = if @protocols
      new WebSocket(@url, @protocols)
    else
      new WebSocket(@url)

    if @binaryMode
      ws.binaryType = 'arraybuffer'

    ws.onopen    = (evt) => @onopen(evt)
    ws.onclose   = (evt) => @onclose(evt)
    ws.onerror   = (evt) => @onerror(evt)

    ws.onmessage = (ev) =>
      message = ev.data
      if @binaryMode && (message instanceof ArrayBuffer)
        decoded = utf8Decode(message)

        # Create prototyped object because we can't modify
        # attributes like ev.data in the original event object
        ev = Object.create ev,
          data:
            value: decoded
          # Forward-compatible: new code that really want to
          # read the websocket in binary format can still
          # access the raw buffer at ev.binaryData instead of
          # ev.data
          binaryData:
            value: message

      if ev.data == 'h'
        @heartbeat()
        return
      @onmessage(ev)

    ws._onopen = =>
      @retries = 0
      @heartbeat()

    ws._onclose = =>
      ws.removeEventListener 'open',  ws._onopen,  false
      ws.removeEventListener 'close', ws._onclose, false
      window.clearInterval(@heartbeatTimer)
      @heartbeatTimer = null
      @retry() if @shouldRetry && !ws._noRetry

    ws.addEventListener 'open',  ws._onopen,  false
    ws.addEventListener 'close', ws._onclose, false

  heartbeat: ->
    window.clearInterval(@heartbeatTimer)
    @heartbeatTimer = window.setInterval(=>
      @close(true)
    , @heartbeatTimeout)
    @send 'h'

  retry: ->
    delay = if @retries <= 5
      2000
    else if @retries <= 10
      3000
    else if @retries > 10
      5000
    window.clearTimeout(@retryTimeout)
    @retryTimeout = window.setTimeout(=>
      @open()
    , delay)
    @retries += 1

  send: (data) ->
    if @binaryMode && typeof(data) == 'string'
      data = utf8Encode(data)
    try
      @ws?.send(data)

  close: (retry=false) ->
    if ws = @ws
      ws._noRetry = !retry
      ws.close?()

  onbeforeopen: ->
  onopen: ->
  onclose: ->
  onmessage: ->
  onerror: ->

Object.defineProperties window.SocketConnection.prototype,
  binaryType     : { get: -> @ws?.binaryType }
  bufferedAmount : { get: -> @ws?.bufferedAmount }
  extensions     : { get: -> @ws?.extensions }
  protocol       : { get: -> @ws?.protocol }
  readyState     : { get: -> @ws?.readyState }
