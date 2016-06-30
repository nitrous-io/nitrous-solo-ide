App.IdeEditorPaneView = Em.View.extend App.IdeTabViewMixin,
  templateName: 'ide/editor-pane'
  classNames: ['ide-editor-pane-view']
  classNameBindings: ['editorPane.active']

  editorPane: null

  mouseDown: (evt) ->
    $this = @$()
    $target = $(evt.target)

    # ignore if close pane button is being clicked
    return true if $target.closest('.close-pane-button').length > 0

    # activate pane only the closest editor pane
    if $target.closest('.ide-editor-pane-view').is($this)
      Em.run.scheduleOnce 'afterRender', =>
        @get('editorPane').makeActive()
    true

  dragEnter: (event) ->
    editorPane = @get 'editorPane'
    App.IdeEditorTabView.dropEditorPane = editorPane
    App.IdeEditorTabView.dropIndex = editorPane.get 'length'
    false

  actions:
    didClickNew: ->
      @set('controller.activePane', @get('editorPane'))
      @_super.apply this, arguments

    didClickClosePane: ->
      @get('editorPane').close()
      false
