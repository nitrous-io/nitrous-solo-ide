require './socket/socket'

App.EventsSocket = Lib.Socket.extend
  init: ->
    @_super.apply this, arguments

  connect: ->
    origin = location.protocol.replace('http', 'ws') + "//" + location.host
    token = encodeURIComponent(App.get('token'))
    @set 'url', "#{origin}/api/v0/events?token=#{token}"
    @_super.apply this, arguments

  didOpen: (ev) ->
    @_super.apply this, arguments

  didReceiveMessage: (ev) ->
    msg = JSON.parse(ev.data)
    console.log msg.name, msg.data
    @trigger msg.name, msg.data
    @_super.apply this, arguments
