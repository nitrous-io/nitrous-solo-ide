require './ot'

class ot.CollabSocketAdapter
  constructor: (sock, namespace) ->
    @sock = sock
    @namespace = namespace

    sock.on "registered|#{namespace}", (data) =>
      # noop

    sock.on "left|#{namespace}", (data) =>
      clientId = data.conn_id
      @trigger 'client_left', clientId

    sock.on "disconnected|#{namespace}", (data) =>
      clientId = data.conn_id
      @trigger 'client_left', clientId

    sock.on "joined|#{namespace}", (data) =>
      clientId = data.conn_id
      name = data.username
      @trigger 'set_name', clientId, name

    sock.on "ok|#{namespace}", =>
      @trigger 'ack'

    sock.on "op|#{namespace}", (data) =>
      clientId = data[0]
      operation = data[1]
      selection = data[2]
      @trigger 'operation', operation
      @trigger 'selection', clientId, selection

    sock.on "sel|#{namespace}", (data) =>
      clientId = data[0]
      selection = data[1]
      revision = data[2]
      @trigger 'selection', clientId, selection, revision

    sock.on "rejoined|#{namespace}", =>
      @trigger 'reconnect'

    @onReconnected = =>
      @sock.send @namespace, 'rejoin'

    sock.on 'reconnected', @onReconnected

  sendOperation: (revision, operation, selection) ->
    @sock.send @namespace, 'op', revision, operation, selection

  sendSelection: (selection, revision) ->
    @sock.send @namespace, 'sel', selection, revision

  registerCallbacks: (cb) ->
    @callbacks = cb

  trigger: (event) ->
    args = Array.prototype.slice.call(arguments, 1)
    action = @callbacks && @callbacks[event]
    action.apply(this, args) if action

  off: ->
    sock = @sock
    namespace = @namespace

    sock.off "registered|#{namespace}", this
    sock.off "left|#{namespace}", this
    sock.off "joined|#{namespace}", this
    sock.off "ok|#{namespace}", this
    sock.off "op|#{namespace}", this
    sock.off "sel|#{namespace}", this

    sock.off 'reconnected', @onReconnected
