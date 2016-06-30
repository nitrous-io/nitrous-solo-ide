require './evented-socket'

App.CollabSocket = klass = App.EventedSocket.extend
  action: 'collab'
  binary: false
  connID: null

  extraParams: (->
    params = []
    if username = App.get('user.username')
      params.push "username=#{username}"
    if connID = @get 'connID'
      params.push "conn_id=#{connID}"
    params.join('&')
  ).property 'App.user.username', 'connID'

  handleMessage: (message) ->
    try
      message = JSON.parse message
    return if !message?  # cannot parse json, ignore message

    [namespace, event, data] = message

    if event == 'connected'
      if @get('connID')
        # connID is already set, it is a reconnect
        @trigger 'reconnected'
      @set 'connID', data.conn_id
      return

    unless namespace
      namespace = 'global'

    if namespace && event
      @trigger("#{event}|#{namespace}", data)

    # force leave, join, disconnected to be global
    if namespace != "global" && (event == "joined" || event == "left" || event == "disconnected")
      d = {data: data, namespace: namespace}
      @trigger "#{event}|global", d
