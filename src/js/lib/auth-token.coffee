prepareError = (message, jqXHR) ->
  err = new Error(message)
  err.jqXHR = jqXHR
  err

App.authToken =
  obtain: (name, callback) ->
    $.get("/auth_token/#{name}").done((data, status, jqXHR) ->
      if data.auth_token?
        callback null, data.auth_token
      else
        callback prepareError('auth_token not found', jqXHR)
    ).fail (jqXHR, status, errMsg) ->
      callback prepareError(errMsg, jqXHR)
