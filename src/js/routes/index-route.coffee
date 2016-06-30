App.IndexRoute = Em.Route.extend
  beforeModel: (transition) ->
    query = window.location.search.slice(1)
    if window.location.pathname == '/ide' && query
      transition.abort()
      window.location.replace "/ide/#/#{query}"
    else
      #window.location.href = '/app/#/'
