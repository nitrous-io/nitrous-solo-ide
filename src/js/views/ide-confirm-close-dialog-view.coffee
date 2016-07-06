App.IdeConfirmCloseDialogView = App.IdeModalDialogView.extend
  templateName: 'confirm-close-dialog'
  elementId: 'ide-confirm-close-dialog-view'
  contentBinding: 'controller.confirmCloseDialog' # ideEditorController

  actions:
    didClickSave: ->
      if tab = @get('content.document')
        controller = @get('controller')
        controller.saveDocument tab
        @hide()

    didClickDontSave: ->
      if tab = @get('content.document')
        @get('controller').removeTab(tab, true)
        @hide()
