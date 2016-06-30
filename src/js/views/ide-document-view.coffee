#= require diff_match_patch

TAB_SIZES = [2, 3, 4, 8]

App.IdeDocumentView = Em.View.extend
  templateName: 'ide/document'
  classNames: ['ide-document-view']
  classNameBindings: ['document.active']

  document: null
  editor: null

  modeBinding: 'document.editorMode'
  autoCloseBracketsBinding: 'controller.autoCloseBrackets'
  highlightLineBinding: 'controller.highlightLine'
  keybindingsBinding: 'controller.keybindings'
  matchBracketsBinding: 'controller.matchBrackets'
  rulerColumnBinding: 'controller.rulerColumn'
  showLineNumbersBinding: 'controller.showLineNumbers'
  showTrailingSpaceBinding: 'controller.showTrailingSpace'
  softTabsBinding: 'controller.softTabs'
  tabSizeBinding: 'controller.tabSize'
  themeBinding: 'controller.theme'
  wrapLinesBinding: 'controller.wrapLines'
  fontSizeBinding: 'controller.fontSize'
  autocompleteBinding: 'controller.autocomplete'

  foldGutterClass: 'CodeMirror-foldgutter'

  collabMode: false

  otClient: Em.computed.alias 'document.otClient'
  # if set, it will be used when otClient is initialized
  otUndoManagerOverride: Em.computed.alias 'document.otUndoManagerOverride'

  shouldReloadDocument: false # set to true to reload doc and restart collab session

  activeLineWidgets: Em.A([])

  didInsertElement: ->
    @_super()
    @insertEditor()
    if fileName = @get 'document.path.absolutePath'
      @set 'mode', App.FileTypeDetect.detect(fileName)
      @set 'collabMode', true
    $(window).on "unload.#{@get('elementId')}", =>
      @leaveCollab()
      return # need to return void
    @watchOffset()

  willDestroyElement: ->
    @_super()
    @destroyEditor()
    @leaveCollab()
    @stopWatchOffset()
    $(window).off "unload.#{@get('elementId')}"

  collabNamespace: (->
    containerSlug = App.get 'container.slug'
    collabPath = @get 'document.path.collabPath'
    if containerSlug && collabPath
      "#{containerSlug}:#{collabPath}"
  ).property 'App.container.slug', 'document.path.collabPath'

  modeName: (->
    CodeMirror.MODES[@get('mode')]
  ).property 'mode'

  availableModes: (->
    mode = @get 'mode'
    _.map CodeMirror.MODES_ARRAY, (m) ->
      { name: m.name, mode: m.mode, active: m.mode == mode }
  ).property 'mode'

  availableTabSizes: (->
    tabSize = @get 'tabSize'
    _.map TAB_SIZES, (size) ->
      { size: size, active: size == tabSize }
  ).property 'tabSize'

  saving: (->
    if loadCount = @get 'document.path.loadCount'
      loadCount > 0
  ).property 'document.path.loadCount'

  savingDisabled: (->
    @get('saving') || App.get('offline') || App.get('router.ideController.opsSocketNotReady')
  ).property 'saving', 'App.offline', 'App.router.ideController.opsSocketNotReady'

  triggerSelectNext: (->
    if @get('document.selectNextTrigger') && (editor = @get 'editor')
      editor.selectNext()
      @set 'document.selectNextTrigger', false
  ).observes 'document.selectNextTrigger'

  triggerFoldCode: (->
    if @get('document.foldCodeTrigger') && (editor = @get 'editor')
      editor.fold()
      @set 'document.foldCodeTrigger', false
  ).observes 'document.foldCodeTrigger'

  triggerUnfoldCode: (->
    if @get('document.unfoldCodeTrigger') && (editor = @get 'editor')
      editor.unfold()
      @set 'document.unfoldCodeTrigger', false
  ).observes 'document.unfoldCodeTrigger'

  triggerToggleComment: (->
    if @get('document.toggleCommentTrigger') && (editor = @get 'editor')
      editor.toggleComment()
      @set 'document.toggleCommentTrigger', false
  ).observes 'document.toggleCommentTrigger'

  triggerSplitSelectionIntoLines: (->
    if @get('document.splitSelectionIntoLinesTrigger') && (editor = @get 'editor')
      editor.splitSelectionIntoLines()
      @set 'document.splitSelectionIntoLinesTrigger', false
  ).observes 'document.splitSelectionIntoLinesTrigger'

  triggerRemoveTrailingWhitespace: (->
    if @get('document.removeTrailingWhitespaceTrigger') && (editor = @get 'editor')
      editor.removeTrailingWhitespace()
      @set 'document.removeTrailingWhitespaceTrigger', false
  ).observes 'document.removeTrailingWhitespaceTrigger'

  closeDocument: (->
    if @get 'document.path.deleted'
      this.remove()
  ).observes 'document.path.deleted'

  setPlugin: (->
    if editor = @get('editor')
      editor.set 'documentPlugin', @get('document.plugin')
  ).observes 'document.plugin'

  jumpToLine: (->
    if line = @get 'document.goToLine'
      @set 'document.goToLine', null
      if typeof(line) == "number"
        @get('editor')?.goToLine(line)
        return

      @get('editor')?.goToLine(line.line+1, line.cursor)
  ).observes 'document.goToLine'

  addLineWidgets: (->
    @get('activeLineWidgets').forEach (line)->
      line.clear()
    @get('activeLineWidgets').clear()
    if (editor = @get('editor')) && (lineWidgets = @get('document.lineWidgets'))
      lineWidgets.forEach (w)=>
        obj = editor.addLineWidget w.line, w.node, (w.options || {})
        if obj
          @get('activeLineWidgets').pushObject obj
  ).observes 'document.lineWidgets.@each'

  triggerEditorStyleChange: (->
    @setStyles()
  ).observes 'fontSize'

  setStyles: ->
    style = []

    if fs = @get('fontSize')
      style.push "font-size: #{fs}px"

    @get('editor')?.set 'wrapperStyling', style.join("; ")

  insertEditor: ->
    $codeEditor = @$('.code-editor')
    return if $codeEditor.length == 0

    settings = @getProperties(App.Editor.SETTINGS)
    settings.domTarget = $codeEditor[0]
    settings.mode = @get 'mode'
    settings.text = @get 'document.content'
    editor = App.Editor.create(settings)

    if selections = @get('document.selections')
      editor.setSelections(selections)

    if scroll = @get('document.scrollPosition')
      editor.scrollTo(scroll)

    editor.on 'change', =>
      unless @get 'isDestroyed'
        if @get('document.content') != (content = editor.get('text'))
          @set 'document.content', content
        if @get('document.clean') != (clean = editor.isClean())
          @set 'document.clean', clean

    editor.on 'focus', =>
      if !@get 'document.focused'
        @set 'document.focused', true

      parentView = @get 'parentView'
      if parentView instanceof App.IdeEditorPaneView
        Em.run.scheduleOnce 'afterRender', =>
          parentView.get('editorPane')?.makeActive()

      @get('controller')?.trackActivity()

    editor.on 'blur', =>
      if @get 'document.focused'
        @set 'document.focused', false

    editor.on 'cursorActivity', (cm) =>
      # Save selections so that we can restore them when document tab is dragged
      # and dropped.
      if selections = cm.listSelections()
        @set 'document.selections', selections

      # Track any cursor activity as user activity.
      @get('controller')?.trackActivity()

    editor.on 'scroll', (cm) =>
      if scroll = cm.getScrollInfo()
        @set 'document.scrollPosition', {left: scroll.left, top: scroll.top}

    @set 'editor', editor
    @setStyles()

  destroyEditor: ->
    if editor = @get 'editor'
      editor.destroy()
      @set 'editor', null

  updateEditor: (setting) ->
    if editor = @get 'editor'
      editor.set setting, @get(setting)

  # don't call this method directly, instead, set collabMode to true
  _joinCollab: ->
    return unless namespace = @get 'collabNamespace'
    return if @get 'otClient'
    editor = @get 'editor'
    editor.set 'readOnly', true
    cm = editor.get 'codeMirror'
    collabSocket = App.get 'router.ideController.collabSocket'
    doc = @get 'document.content'

    collabSocket.one "doc|#{namespace}", (data) =>
      if data.document != doc
        @set 'document.content', data.document
      serverAdapter = new ot.CollabSocketAdapter(collabSocket, namespace)
      editorAdapter = new ot.CodeMirrorAdapter(cm)
      otClient = new ot.EditorClient(data.revision, data.clients, serverAdapter, editorAdapter)
      if undoManager = @get 'otUndoManagerOverride'
        otClient.undoManager = undoManager
        @set 'otUndoManagerOverride', null
      @set 'otClient', otClient
      editor.set 'readOnly', false
      @focusedDidChange()

    collabSocket.on "rejoin_failed|#{namespace}", =>
      editor.set 'readOnly', true
      @set 'shouldReloadDocument', true

    collabSocket.send(namespace, 'join', doc)

  leaveCollab: ->
    @set 'collabMode', false
    return unless otClient = @get 'otClient'
    collabSocket = App.get 'router.ideController.collabSocket'

    if namespace = @get 'collabNamespace'
      collabSocket.send(namespace, 'leave')
      collabSocket.off "rejoin_failed|#{namespace}"

    @clearCollabCursors(otClient)

    otClient.serverAdapter.off()
    otClient.serverAdapter = null
    otClient.editorAdapter.detach()
    otClient.editorAdapter = null
    @set 'otClient', null

  clearCollabCursors: (otClient)->
    collabClientIDs = Object.keys(otClient.clients)
    collabClientIDs.forEach (id) =>
      otClient.clients[id].remove()

  collabModeDidChange: (->
    if @get('collabMode') && @get('controller.collabSocketReady')
      @_joinCollab()
  ).observes 'collabMode', 'controller.collabSocketReady'

  shouldReloadDocumentDidChange: (->
    return unless @get('shouldReloadDocument') && @get('controller.opsSocketReady')
    @set 'shouldReloadDocument', false
    doc = @get 'document'
    return unless fileName = doc.get 'path.absolutePath'
    @leaveCollab()
    controller = @get 'controller'
    opsSocket = controller.get 'opsSocket'
    opsSocket.fetchFileContent fileName, (err, absolutePath, contentType, content) =>
      if err || contentType?.match(/^image/)
        controller.removeTab(doc, true)
        return
      doc.set 'content', content
      @set 'collabMode', true
  ).observes 'shouldReloadDocument', 'controller.opsSocketReady'

  modeDidChange: (->
    @updateEditor('mode')
  ).observes 'mode'

  tabSizeDidChange: (->
    @updateEditor('tabSize')
  ).observes 'tabSize'

  softTabsDidChange: (->
    @updateEditor('softTabs')
  ).observes 'softTabs'

  themeDidChange: (->
    @updateEditor('theme')
  ).observes 'theme'

  wrapLinesDidChange: (->
    @updateEditor('wrapLines')
  ).observes 'wrapLines'

  highlightLineDidChange: (->
    @updateEditor('highlightLine')
  ).observes 'highlightLine'

  showLineNumbersDidChange: (->
    @updateEditor('showLineNumbers')
  ).observes 'showLineNumbers'

  rulerColumnDidChange: (->
    @updateEditor('rulerColumn')
  ).observes 'rulerColumn'

  showTrailingSpaceDidChange: (->
    @updateEditor('showTrailingSpace')
  ).observes 'showTrailingSpace'

  matchBracketsDidChange: (->
    @updateEditor('matchBrackets')
  ).observes 'matchBrackets'

  autoCloseBracketsDidChange: (->
    @updateEditor('autoCloseBrackets')
  ).observes 'autoCloseBrackets'

  keybindingsDidChange: (->
    @updateEditor('keybindings')
  ).observes 'keybindings'

  autocompleteDidChange: (->
    @updateEditor('autocomplete')
  ).observes 'autocomplete'

  contentDidChange: (->
    if editor = @get 'editor'
      editor.set 'text', @get 'document.content'
  ).observes 'document.content'

  cmDelete: (cm, start, end) ->
    from = cm.posFromIndex(start)
    to = cm.posFromIndex(end)
    cm.replaceRange '', from, to

  cmInsert: (cm, start, s) ->
    from = cm.posFromIndex(start)
    cm.replaceRange s, from, from

  removeFirstPatchIfPreserve: (patch) ->
    return unless patch.diffs.length > 0
    diff = patch.diffs[0]
    type = diff[0]
    return unless type == 0
    n = diff[1].length
    patch.start1 += n
    patch.length1 -= n
    # remove first diff
    patch.diffs.splice 0, 1

  removeLastPatchIfPreserve: (patch) ->
    n = patch.diffs.length
    return unless n > 0
    diff = patch.diffs[n-1]
    return unless diff[0] == DIFF_EQUAL
    s = diff[1]
    patch.length1 -= s.length
    # remove last diff
    patch.diffs.splice n-1, 1

  # patch_diff_match library generates diff that are meant to be applied fuzzily
  # so they add a bit of before/after context for finding the text to change.
  # We do exact match and this additional context is not needed and causes
  # unnecessary modifications, so we remove first and last diff component
  # if they are just for context
  optimizePatch: (patch) ->
    @removeFirstPatchIfPreserve patch
    @removeLastPatchIfPreserve patch

  applyPatch: (cm, patch) ->
    @optimizePatch patch
    start = patch.start1
    end = start + patch.length1
    cm.operation =>
      @cmDelete cm, start, end
      patch.diffs.forEach (diff) =>
        type = diff[0] # 0 : DIFF_EQUAL, 1 : DIFF_INSERT, -1 : DIFF_DELETE
        text = diff[1]
        # DIFF_DELETE is a no-op because it got deleted with
        # the first cmDelete()
        if type == DIFF_EQUAL
          @cmInsert cm, start, text
          start += text.length
        else if type == DIFF_INSERT
          @cmInsert cm, start, text
          start += text.length

  # a hack but the best we could come up with
  # if we want to replace content of the editor and preserve current line etc.
  triggerReplaceContent: (->
    newContent = @get 'document.replaceContentTrigger'
    return unless newContent != null
    editor = @get 'editor'
    cm = editor?.codeMirror
    return unless cm

    currContent = cm.getValue()
    if currContent == newContent
      @set 'document.clean', true
      return

    # heuristic: replacing content by diffing is only meant for relatively
    # small changes (e.g. those we can expect to get by runnign goimports on
    # .go code). if a change is too big, we replace the whole thing
    lenDiff = Math.abs(currContent.length - newContent.length)
    if lenDiff > 4*1024
      selections = cm.listSelections()
      lastLine = cm.lastLine()
      len = cm.getLine(lastLine).text.length

      from = {line: 0, ch: 0}
      to = {line: lastLine, ch: len}
      editor.replaceRange newContent, from: from, to: to
      editor.setSelections(selections)
    else
      differ = new diff_match_patch
      patches = differ.patch_make(currContent, newContent)
      for patch in patches
        @applyPatch cm, patch

    # this will call triggerReplaceContent again which is why we filter out null above
    @set 'document.replaceContentTrigger', null
    @set 'document.clean', true
  ).observes 'document.replaceContentTrigger'

  documentReadOnlyDidChange: (->
    @set 'editor.readOnly', @get('document.readOnly')
  ).observes 'document.readOnly'

  documentCleanDidChange: (->
    return unless editor = @get 'editor'
    documentIsClean = @get('document.clean')

    if documentIsClean && editor.isClean() != documentIsClean
      editor.markClean()
  ).observes 'document.clean'

  consoleFullscreenDidChange: (->
    consoleFullscreen = App.get 'consoleFullscreen'
    editor = @get 'editor'
    if editor && !consoleFullscreen
      Em.run.scheduleOnce 'afterRender', ->
        editor.refresh()
  ).observes 'App.consoleFullscreen'

  consoleMinimizedDidChange: (->
    editor = @get 'editor'
    Em.run.scheduleOnce 'afterRender', ->
      editor.refresh()
  ).observes 'App.consoleMinimized'

  activeDidChange: (->
    editor = @get 'editor'
    active = @get 'document.active'
    if editor && active
      Em.run.scheduleOnce 'afterRender', ->
        editor.refresh()
  ).observes 'document.active'

  focusedDidChange: (->
    return unless editor = @get 'editor'
    if @get 'document.focused'
      Em.run.scheduleOnce 'afterRender', ->
        editor.refresh()
        editor.focus()
    else
      editor.blur()
  ).observes 'document.focused'

  documentPathDidChange: (->
    if fileName = @get 'document.path.absolutePath'
      @set 'mode', App.FileTypeDetect.detect(fileName)
      @set 'collabMode', true

    ###
    On file rename, leave the collab session under the old filename, and
    join a new session under the new file name. Otherwise the collaborator
    will not be able to collaborate on the newly named file.
    ###
    @leaveCollab()
    @set 'document.path.collabPath', fileName
    @_joinCollab()
  ).observes 'document.path.absolutePath'

  watchOffset: ->
    @watchOffsetTimer = window.setInterval(=>
      return unless @get('document.active')
      if editor = @get('editor')
        @set 'document.currentOffset', editor.getOffset()
    , 100)

  stopWatchOffset: ->
    if @watchOffsetTimer
      window.clearInterval(@watchOffsetTimer)

  actions:
    didClickLineCol: ->
      @get('controller')?.showGoToLineDialog()

    didSelectMode: (selectedMode) ->
      @set 'mode', selectedMode

    didSelectTabSize: (selectedTabSize) ->
      @set 'tabSize', selectedTabSize

    didClickSoftTabToggle: ->
      @set 'softTabs', !@get('softTabs')
