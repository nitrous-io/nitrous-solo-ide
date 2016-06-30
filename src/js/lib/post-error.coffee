window.App.reopen
  postError: (err={}, def) -> # def: default
    if typeof err == 'string'
      msg = err?.capitalize()
    msg ||= err.error_description?.capitalize()
    unless msg
      msg = def?.capitalize() || 'Something went wrong'
      if err.error
        msg += ": #{err.error}"
    if err.error_hash
      msg += " (Error code: #{err.error_hash})"
    App.snackbar.post(msg, sticky: true)
