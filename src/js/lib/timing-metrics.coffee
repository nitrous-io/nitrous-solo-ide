window.App ||= {}

App.TimingMetrics =
  record: (metric, duration, opts = {}) ->
    data = _.extend { duration: duration }, opts

    $.ajax
      url: "/timing/#{metric}"
      dataType: 'json'
      type: 'POST'
      data: data
