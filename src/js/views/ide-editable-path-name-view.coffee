App.IdeEditablePathNameView = Em.View.extend
  templateName: 'editable-path-name'
  classNames: ['ide-editable-path-name-view']

  path: null
  newPathName: ''

  didInsertElement: ->
    @_super()
    if path = @get 'path'
      currentPathName = unless path.get 'new' then path.get 'name' else ''
      @set 'newPathName', currentPathName

  didFinishEditing: ->
    path = @get 'path'
    if path.get 'new'
      @get('controller').saveNewPath path, @get('newPathName')
    else
      @get('controller').applyRenamedPath path, @get('newPathName')

  didCancelEditing: ->
    path = @get 'path'
    if path.get 'new'
      @get('controller').cancelNewPath path
    else
      @get('controller').resetRenamedPath path

App.IdeEditablePathNameTextField = Em.TextField.extend
  finished: false

  didBecomeDisabled: (->
    if @get 'disabled'
      @$().blur()
  ).observes 'disabled'

  didInsertElement: ->
    @_super()
    @$().focus()

  insertNewline: ->
    if @get('value').trim().length > 0
      this.doneEditing()
    else
      this.cancelEditing()

  focusOut: ->
    this.insertNewline()

  keyDown: (event) ->
    this.cancelEditing() if event.keyCode == 27 # escape key

  doneEditing: ->
    unless @get 'finished'
      @set 'finished', true
      @set 'disabled', true
      @get('parentView').didFinishEditing()

  cancelEditing: ->
    unless @get 'finished'
      @set 'finished', true
      @set 'disabled', true
      @get('parentView').didCancelEditing()
