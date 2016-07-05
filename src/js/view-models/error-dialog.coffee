###
ErrorDialog shows general errors in the IDE and
offers option for user to be redirected back to
the main app.
###
App.ErrorDialog = Em.Object.extend
  errorTitle: 'An error has occured'
  errorMessage: 'An error has occured'
  redirectUrl: "/app"
  okButtonText: 'OK'
