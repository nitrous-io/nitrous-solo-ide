App.IdeConfirmDeletePathDialogView = App.IdeModalDialogView.extend
  templateName: 'confirm-delete-path-dialog'
  elementId: 'confirm-delete-path-dialog-view'

  contentBinding: 'controller.confirmDeletePathDialog' # IdeSidebarController

  actions:
    didClickDelete: ->
      if path = @get('content.path')
        controller = @get('controller')
        controller.delete path
        @hide()
