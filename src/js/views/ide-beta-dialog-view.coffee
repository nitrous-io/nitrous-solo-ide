App.IdeBetaDialogView = App.IdeModalDialogView.extend
  templateName: 'ide/beta-dialog'
  elementId: 'beta-dialog-view'
  contentBinding: 'controller.showBetaDialog'

  showOrHide: (->
    if @get 'content'
      @show()
    else
      @hide()
  ).observes 'content'

  viewDidDisappear: ->
    @set 'content', false

  actions:
    didClickOK: ->
      if editorController = App.get('router.ideEditorController')
        editorController.set('beta', true)
      @hide()
