App.IdeFindInProjectDialogView = App.IdeModalDialogView.extend
  templateName: 'find-in-project-dialog'
  elementId: 'ide-find-in-project-dialog-view'
  contentBinding: 'controller.findInProjectDialog'

  termFieldInvalid: Em.computed.equal('controller.invalidField', 'term')

  viewDidDisappear: ->
    @_super()
    @get('controller.controllers.ideEditor.activeTab')?.set 'focused', true

  keyDown: (e) ->
    switch e.which
      when 13 # Enter
        e.preventDefault()
        e.stopPropagation()
        @find()
      when 27 # Escape
        @hide()

  find: ->
    @get('controller').send 'find'

  actions:
    didClickFind: ->
      @find()
      false
