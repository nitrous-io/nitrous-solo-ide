App.IdeErrorDialogView = App.IdeModalDialogView.extend
  templateName: 'error-dialog'
  elementId: 'ide-error-dialog-view'
  contentBinding: 'controller.errorDialog'

  viewDidAppear: (e)->
    @_super()
    App.set('router.ideEditorController.activeTab.focused', false)

    # we can't get focus without a text element
    # so we grab Escape from window
    $(window).bind 'keydown.ideErrorDialog', (e)=>
      if e.keyCode == 27
        e.preventDefault()
        @hide()

  viewDidDisappear: ->
    @_super()
    App.set('router.ideEditorController.activeTab.focused', true)
    $(window).unbind 'keydown.ideErrorDialog'

  actions:
    didClickOK: ->
      @hide()
      return unless @get('content.redirectUrl')

      if @get('content.newWindow')
        window.open(@get('content.redirectUrl'), '_blank')
        return

      # unbind to prevent confirm-close-window popup
      $(window).unbind 'beforeunload.ide'
      window.location.href = @get('content.redirectUrl')

    didClickCancel: ->
      @hide()
