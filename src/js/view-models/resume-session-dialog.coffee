###
ResumeSessionDialog informs user that the session is being resumed while we restart 
the host and/or container for the user, if host and/or container are not in a running 
state when they access the IDE.
###
App.ResumeSessionDialog = Em.Object.extend
  message: 'Resuming Session...'
