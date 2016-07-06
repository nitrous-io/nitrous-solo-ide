App.IdeSaveDialogView = App.IdeModalDialogView.extend
  templateName: 'save-dialog'
  elementId: 'ide-save-dialog-view'
  contentBinding: 'controller.saveDialog' # ideEditorController

  disableSaveButton: Em.computed.empty 'content.path'

  didReceiveError: (->
    path = @get 'content.path'
    error = @get('content.firstErrors.path') || @get('content.firstErrors.base')
    if error
      error = "“#{path || '(empty)'}” #{error}"
      App.snackbar.post(error)
  ).observes 'content.firstErrors'

  actions:
    didClickSave: ->
      @get('controller').saveNewDocument()
