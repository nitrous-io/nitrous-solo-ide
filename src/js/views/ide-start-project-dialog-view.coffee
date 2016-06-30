App.IdeStartProjectDialogView = App.IdeModalDialogView.extend
  templateName: 'ide/start-project-dialog'
  elementId: 'ide-start-project-dialog-view'
  contentBinding: 'controller.startProjectDialog'

  containerStartedBinding: 'controller.containerStarted'

  starting: false

  observeContainerStarted: (->
    if @get('containerStarted')
      @hide()
      @set('starting', false)
  ).observes 'containerStarted'

  actions:
    didClickReturnToDashboard: ->
      dashboardUrl = @get('content.dashboardUrl')
      return unless dashboardUrl
      @hide()

      # unbind to prevent confirm-close-window popup
      $(window).unbind 'beforeunload.ide'
      window.location.href = dashboardUrl

    didClickStartProject: ->
      @set('starting', true)
      @get('controller').startHostAndContainer()
