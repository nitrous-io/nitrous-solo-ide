window.App ||= {}

App.localStorage =
  set: (key, value) ->
    if value == null || value == undefined
      window.localStorage.removeItem "aio:#{key}"
    else
      window.localStorage.setItem "aio:#{key}", JSON.stringify(value)

  get: (key) ->
    if json = window.localStorage.getItem "aio:#{key}"
      JSON.parse json

  # delete the key and return its content
  delete: (key) ->
    if json = window.localStorage.getItem "aio:#{key}"
      window.localStorage.removeItem "aio:#{key}"
      JSON.parse json
