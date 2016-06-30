App.IdeResumeSessionDialogView = App.IdeModalDialogView.extend
  templateName: 'ide/resume-session-dialog'
  elementId: 'ide-resume-session-dialog-view'
  contentBinding: 'controller.resumeSessionDialog'

  hostStartedBinding: 'controller.hostStarted'
  hostRestartedBinding: 'controller.hostRestarted'
  containerStartedBinding: 'controller.containerStarted'
  containerRestartedBinding: 'controller.containerRestarted'

  hostAndContainerStateDidChange: (->
    if @get('hostStarted') && @get('containerStarted')
      @hide()
  ).observes 'hostStarted', 'containerStarted'

  containerStateDidChange: (->
    if @get('containerStarted') || @get('containerRestarted')
      @hide()
  ).observes 'containerStarted', 'containerRestarted'

  hostStateDidChange: (->
    if @get('hostRestarted')
      @hide()
  ).observes 'hostRestarted'
