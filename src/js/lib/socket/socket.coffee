require './socket-connection'

Lib.Socket = Em.Object.extend Em.Evented,
  url: null
  connected: false
  disconnected: Em.computed.not 'connected'

  init: ->
    @_super.apply this, arguments
    @_conn = conn = new SocketConnection # not using @set to reduce overhead

    conn.onbeforeopen   = => @willOpen()
    conn.onopen    = (ev) => @didOpen(ev)
    conn.onmessage = (ev) => @didReceiveMessage(ev)
    conn.onerror   = (ev) => @didFail(ev)
    conn.onclose   = (ev) => @didClose(ev)

  connect: (nobeforeopen) ->
    @_conn.url = @get 'url'
    @_conn.open(nobeforeopen)

  disconnect: ->
    @_conn?.close()

  retry: ->
    @_conn?.retry()

  destroy: ->
    @_conn = undefined

  send: (data) ->
    @_conn?.send(data)

  willOpen: (ev) ->
    @_conn.url = @get 'url'
    @trigger 'beforeopen', ev

  didOpen: (ev) ->
    @set 'connected', true
    @trigger 'open', ev

  didReceiveMessage: (ev) ->
    @trigger 'message', ev.data

  didFail: (ev) ->
    @set 'connected', false
    @trigger 'error', ev

  didClose: (ev) ->
    @set 'connected', false
    @_conn.url = null
    @trigger 'close', ev
