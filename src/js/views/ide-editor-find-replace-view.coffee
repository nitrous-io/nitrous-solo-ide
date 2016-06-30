App.IdeEditorFindReplaceView = Em.View.extend
  templateName: 'ide/editor-find-replace'
  classNames: ['ide-editor-find-replace-view']
  classNameBindings: ['hidden']

  document: null

  hidden: true

  useRegex: false
  matchCase: false
  showReplace: false

  searchText: ''
  replacementText: ''

  editorBinding: Em.Binding.oneWay 'parentView.editor'

  documentFindTriggerDidChange: (->
    if @get 'document.findTrigger'
      @setProperties
        showReplace: false
        hidden: false
      @set 'document.findTrigger', false
      @focus(true)
    @refreshEditor()
  ).observes 'document.findTrigger'

  documentFindNextTriggerDidChange: (->
    return unless @get 'document.findNextTrigger'
    return if @get('searchText') == ''
    @setProperties
      showReplace: false
      hidden: false
    @set 'document.findNextTrigger', false
    @refreshEditor()
    @find(false)
  ).observes 'document.findNextTrigger'

  documentFindPrevTriggerDidChange: (->
    return unless @get 'document.findPrevTrigger'
    return if @get('searchText') == ''
    @setProperties
      showReplace: false
      hidden: false
    @set 'document.findPrevTrigger', false
    @refreshEditor()
    @find(true)
  ).observes 'document.findPrevTrigger'

  documentReplaceTriggerDidChange: (->
    if @get 'document.replaceTrigger'
      @setProperties
        showReplace: true
        hidden: false
      @set 'document.replaceTrigger', false
      @focus(true)
    @refreshEditor()
  ).observes 'document.replaceTrigger'

  focus: (selectText) ->
    Em.run.scheduleOnce 'afterRender', this, ->
      @$('.search-text').focus()
      if selectText
        @$('.search-text').select()

  refreshEditor: ->
    Em.run.scheduleOnce 'afterRender', =>
      @get('editor')?.refresh()

  find: (reverse) ->
    matchCase = @get 'matchCase'
    useRegex = @get 'useRegex'
    if query = @get 'searchText'
      found = @get('editor')?.find(query, reverse, matchCase, useRegex)
      if found
        @set('document.findError', null)
      else
        @set('document.findError', "No matches for #{query}")

  replace: (all) ->
    matchCase = @get 'matchCase'
    useRegex = @get 'useRegex'
    text = @get 'replacementText'
    if query = @get 'searchText'
      @get('editor')?.replace(query, text, all, matchCase, useRegex)

  actions:
    close: ->
      @set 'hidden', true
      return unless editor = @get('editor')
      editor.clearSearch()
      editor.focus()
      @set('document.findError', null)

    findNext: ->
      @focus(false)
      @find(false)

    findPrev: ->
      @focus(false)
      @find(true)

    replace: ->
      @replace(false)

    replaceAll: ->
      @replace(true)

App.IdeEditorFindReplaceTextField = Em.TextField.extend
  insertNewline: (evt) ->
    if parentView = @get 'parentView'
      if evt.shiftKey
        parentView.send('findPrev')
      else
        parentView.send('findNext')

  keyDown: (evt) ->
    parentView = @get 'parentView'
    return true unless parentView && evt
    switch
      when evt.keyCode == 27 # Esc
        parentView.send('close')
      # Keyboard shortcuts below replicate those of the IDE's Find Next/Prev.
      when evt.keyCode == 71 && evt.metaKey && evt.shiftKey # Cmd-Shift-g
        parentView.send('findPrev')
      when evt.keyCode == 71 && evt.metaKey # Cmd-g
        parentView.send('findNext')
      when evt.keyCode == 114 && evt.shiftKey # Shift-F3
        if !App.util.IsMac
          parentView.send('findPrev')
      when evt.keyCode == 114 # F3
        if !App.util.IsMac
          parentView.send('findNext')
      else
        return true
    false
