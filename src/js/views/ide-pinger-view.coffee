App.IdePingerView = Em.View.extend
  templateName: 'pinger'
  elementId: 'ide-pinger-view'
  attributeBindings: ['title']
  classNameBindings: ['latencyClass']

  latencyBinding: Em.Binding.oneWay 'App.pinger.latency'

  latencyClass: (->
    latency = @get 'latency'
    if latency <= 0
      'unavailable'
    else if latency < 100
      'excellent'
    else if latency < 200
      'good'
    else if latency < 300
      'moderate'
    else if latency < 400
      'poor'
    else
      'appalling'
  ).property 'latency'

  title: (->
    latency = @get 'latency'
    latencyClass = @get 'latencyClass'
    return "Unavailable" if latency <= 0 || !latencyClass
    "Latency: #{latency}ms (#{latencyClass?.capitalize()})"
  ).property 'latencyClass'
