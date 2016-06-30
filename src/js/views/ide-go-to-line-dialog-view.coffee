App.IdeGoToLineDialogView = App.IdeModalDialogView.extend
  templateName: 'ide/go-to-line-dialog'
  elementId: 'ide-go-to-line-dialog-view'
  contentBinding: 'controller.goToLineDialog'

  hide: ->
    @set('content.line', null)
    @_super()

  click: (e) ->
    if $(e.target).is(@$())
      @hide()
    e.stopPropagation()

  keyDown: (e) ->
    switch e.which
      when 13 # Enter
        e.preventDefault()
        e.stopPropagation()
        @goToLine()
      when 27 # Escape
        @hide()

  goToLine: ->
    @get('controller').goToLine()
    @hide()

  viewDidDisappear: ->
    @_super()
    @get('controller.activeTab')?.set 'focused', true
