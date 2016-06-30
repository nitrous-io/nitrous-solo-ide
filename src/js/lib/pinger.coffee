App.Pinger = klass = Em.Object.extend
  latency: 0
  container: null
  url: null

  init: ->
    @_super.apply this, arguments

    if container = @get 'container'
      protocol = location.protocol
      freighterdUrl = container.get 'freighterdUrl'
      @set 'url', "#{protocol}//#{freighterdUrl}/ping"

    @ping()
    window.setInterval(=>
      @ping()
    , @constructor.pingInterval)

  ping: ->
    url = @get 'url'
    return unless url && App.get('online')

    t = +new Date
    Em.$.ajax(
      type: 'POST'
      url: url
      dataType: 'json'
    ).then =>
      t2 = +new Date
      @set 'latency', t2 - t
    , =>
      @set 'latency', -1

klass.reopenClass
  pingInterval: 60000 # millisecond
