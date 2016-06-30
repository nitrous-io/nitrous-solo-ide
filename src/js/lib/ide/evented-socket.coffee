require '../socket/socket'

App.EventedSocket = Lib.Socket.extend Ember.Evented,
  binary: false
  action: null

  container: null
  started: false
  startedFirstTime: false

  nextCallbackId: 0
  callbacks: null

  init: ->
    @_super.apply this, arguments
    @set 'nextCallbackId', 0
    @set 'callbacks', []

  connect: ->
    return unless @get 'container'
    @_super.apply this, arguments

  disconnect: ->
    @_super.apply this, arguments
    @setProperties
      startedFirstTime: false
      started: false
      container: null

  send: (namespace, event, args...) ->
    return unless @_conn
    if _.isFunction(_.last args)
      callback = args.pop()
      callbackId = @registerCallback callback
      msg = { namespace: namespace, event: event, cid: callbackId, args: args }
      @_conn.send "d|#{JSON.stringify(msg)}"
    else
      msg = { namespace: namespace, event: event, args: args }
      @_conn.send "d|#{JSON.stringify(msg)}"

  willOpen: (ev) ->
    @set 'url', null
    @_super.apply this, arguments
    action = @get 'action'
    container = @get 'container'
    protocol = location.protocol.replace('http', 'ws')
    freighterdUrl = container.get 'freighterdUrl'
    cid = container.get 'cid'

    container.requestToken([action]).then (token) =>
      token = encodeURIComponent(token.token)
      url = "#{protocol}//#{freighterdUrl}/containers/#{cid}/#{action}?token=#{token}"
      if extraParams = @get 'extraParams'
        url += '&' + extraParams
      if @get 'binary'
        url += "&binary=true"
        @_conn.binaryMode = true
      @set 'url', url
      # proceed with connection
      @connect(true)
    , (jqxhr) =>
      @retry()

  didOpen: (ev) ->
    @_super.apply this, arguments
    @set 'started', true
    @set('startedFirstTime', true) if !@get('startedFirstTime')

  didReceiveMessage: (event) ->
    @_super.apply this, arguments
    type = event.data.slice(0, 2)
    switch type
      when 'd|'
        @handleMessage(event.data.slice(2))

  didClose: ->
    @_super.apply this, arguments
    if callbacks = @get 'callbacks'
      callbacks.forEach (o, i) =>
        @invokeCallback(i, ['aio:connection:closed'])
    @set 'started', false

  registerCallback: (callback) ->
    callbackId = @get 'nextCallbackId'
    @get('callbacks')[callbackId] = callback
    @incrementProperty('nextCallbackId')
    callbackId

  invokeCallback: (callbackId, args) ->
    callbacks = @get('callbacks')
    if callback = callbacks[callbackId]
      callbacks[callbackId] = null
      callback args...

  handleMessage: (message) ->
    try
      message = JSON.parse message
    return if !message?  # cannot parse json, ignore message

    # check if there are any registered handlers
    # for the incoming event
    # otherwise, try to find corresponding callback
    if @has(message.event)
      @trigger message.event, [message.error].concat(message.args)...
    else
      if message.error
        @invokeCallback message.cid, [message.error]
      else
        @invokeCallback message.cid, [null].concat(message.args)
