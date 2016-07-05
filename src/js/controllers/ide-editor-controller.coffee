CodeMirror = require('../lib/codemirror')

DEFAULT_FONT_SIZE = 14

App.IdeEditorController = Em.ArrayController.extend App.IdeTabControllerMixin,
  content: null
  modelClass: App.Document
  rootPane: null
  activePane: Em.computed.alias 'content'
  saveDialog: null
  confirmCloseDialog: null
  goToLineDialog: null
  chatNotification: null
  tabWatcher: null

  opsSocketBinding: Em.Binding.oneWay 'App.router.ideController.opsSocket'
  opsSocketReadyBinding: Em.Binding.oneWay 'App.router.ideController.opsSocketReady'

  collabEnabledBinding: Em.Binding.oneWay 'App.router.ideController.collabEnabled'
  collabSocketBinding: Em.Binding.oneWay 'App.router.ideController.collabSocket'
  collabSocketReadyBinding: Em.Binding.oneWay 'App.router.ideController.collabSocketReady'

  pingerSocketBinding: Em.Binding.oneWay 'App.pingerSocket'

  activeFilesMonitorBinding: Em.Binding.oneWay 'App.router.ideController.activeFilesMonitor'

  softTabs: true
  tabSize: 2
  theme: 'solarized dark'
  wrapLines: true
  highlightLine: true
  showLineNumbers: true
  rulerColumn: null
  showTrailingSpace: false
  matchBrackets: true
  autoCloseBrackets: true
  removeTrailingWhitespaceOnSave: true
  keybindings: 'default'
  fontSize: null

  trackActivityQueued: false

  initialize: ->
    editorPane = App.EditorPane.create(tabs: Em.A())
    @set 'rootPane', editorPane
    @set 'activePane', editorPane
    @set 'tabWatcher', new TabWatcher(editorPane, App.get('container'))

    @useUserSettings()

    # We do this so that saving using :w in Vim mode works.
    # Sucks that this is a CodeMirror "global".
    CodeMirror.commands.save = (cm) =>
      @saveDocument(@get('activeTab'))

  opsSocketDidStartForTheFirstTime: (->
    if @get 'opsSocket.startedFirstTime'
      socket = @get 'opsSocket'
      socket.on 'fileChanged.output', _.bind(@handleFileChanged, this)
  ).observes 'opsSocket.startedFirstTime'

  reset: ->
    @set 'content', null
    @set 'saveDialog', null
    @set 'confirmCloseDialog', null
    if @get 'goToLineDialog'
      @set 'goToLineDialog.hide', true
      @set 'goToLineDialog', null

  useUserSettings: ->
    userSettings = App.get('userSettings') || {}
    _.each App.Editor.SETTINGS, (k) =>
      setting = userSettings[k.underscore()]
      if setting?
        @set(k, setting)
      @addObserver(k, this, 'updateUserSettings')

  updateUserSettings: ->
    userSettings = App.get('userSettings')
    if userSettings
      _.each App.Editor.SETTINGS, (k) =>
        userSettings[k.underscore()] = @get(k)
      userSettings.requestSave()

  removeTab: (tab, forceRemove=false) ->
    tab = @get 'activeTab' unless tab
    return unless tab
    if tab.get('clean') || forceRemove
      if absPath = tab.get('path.absolutePath')
        opsSocket = @get 'opsSocket'
        opsSocket.unwatchFile absPath

      @_super(tab)
    else
      @set 'confirmCloseDialog', App.ConfirmCloseDialog.create document: tab

  activeTabDidChange: (->
    @get('tabWatcher')?.notifyOfChange()
  ).observes 'activeTab', 'activeTab.selections.@each', 'activeTab.scrollPosition'

  tabsDidChange: (->
    return unless @get 'activeFilesMonitor'
    if rootPane = @get 'rootPane'
      @get('activeFilesMonitor').tabsDidChange(rootPane.allTabs())
  ).observes 'rootPane', 'activeFilesMonitor', 'activeTab', 'content.length'

  handleFileChanged: (err, file) ->
    path = App.Path.create(absolutePath: file)
    if doc = @findProperty 'path', path
      return unless doc.isOTMaster()
      return unless doc.get('clean')

      lastUpdated = doc.get('documentLastUpdated')
      return if lastUpdated && (Date.now() - lastUpdated)/1000 <= 1
      doc.set 'documentLastUpdated', Date.now()
      if sidebar = App.get('router.ideSidebarController')
        sidebar.refreshTextFileContent path

  saveDocument: (doc) ->
    return unless @get 'opsSocketReady'
    return if doc.get('isImageFile')

    if path = doc.get 'path'
      path.incrementProperty 'loadCount'
      doc.set 'readOnly', true
      if @get 'removeTrailingWhitespaceOnSave'
        doc.set 'removeTrailingWhitespaceTrigger', true

      opsSocket = @get 'opsSocket'
      opsSocket.writeFile path.get('absolutePath'), doc.get('content'), (err, absolutePath) =>
        path.decrementProperty 'loadCount'
        doc.setProperties
          readOnly: false
          focused: true
        if err
          App.set 'flashMessage', { type: 'alert-error', text: "Error saving file '#{path.get('absolutePath')}'" }
          return
        doc.set 'documentLastUpdated', Date.now()
        doc.set 'clean', true

        @trackActivity()
    else
      @set 'saveDialog', App.SaveDialog.create document: doc

  saveNewDocument: ->
    return unless @get 'opsSocketReady'
    saveDialog = @get 'saveDialog'
    errors = saveDialog.validate()
    return if errors

    saveDialog.set 'saving', true
    doc = saveDialog.get 'document'
    docContent = doc.get 'content'
    # FIXME probably not the best way to scope to home path
    path = saveDialog.get 'path'
    homePath = App.get('container.homePath')
    absolutePath = "#{homePath}/#{path}"
    doc.set 'readOnly', true

    opsSocket = @get 'opsSocket'
    opsSocket.writeNewFile absolutePath, docContent, _.bind(@didWriteNewFileContent, this)

    @trackActivity()

  didWriteNewFileContent: (err, absolutePath) ->
    saveDialog = @get 'saveDialog'
    doc = saveDialog.get 'document'
    doc.setProperties
      readOnly: false
      focused: true
    if err
      # TODO: Freighter should be returning a proper error code for file exists.
      # Revisit after #381 is merged.
      errors = if err.match /file exists/
        {base: ["already exists. Please enter a different filename."]}
      else
        {base: ["Error occurred while trying to save the file."]}
      saveDialog.set 'errors', errors
    else
      path = App.Path.create absolutePath: absolutePath
      doc.setProperties
        path: path
        clean: true
      sidebarController = App.get 'router.ideSidebarController'
      sidebarController.refreshPath path.get('parentAbsolutePath')
      @set 'saveDialog.hide', true
    saveDialog.set 'saving', false

  addTab: ->
    @_super.apply this, arguments
    @trackActivity()

  # omit `path` or provide `multiple=true` in attrs to allow for multiple tabs
  # with same path
  createTab: (attrs={}, modelClass=null) ->
    rootPane = @get 'rootPane'
    if attrs.multiple != true && rootPane.findBy('path', attrs.path)
      return # disallow duplicate tabs for now, unless specified by caller
    @_super(attrs, modelClass)

  splitActivePaneVertically: ->
    pane = @get 'activePane'
    pane.split()
    @set 'activePane', pane.get('left')

  splitActivePaneHorizontally: ->
    pane = @get 'activePane'
    pane.split(true)
    @set 'activePane', pane.get('left')

  closeActivePane: ->
    pane = @get 'activePane'
    pane.close()

  showGoToLineDialog: ->
    @set 'goToLineDialog', App.GoToLineDialog.create

  goToLine: ->
    lineStr = @get('goToLineDialog.line')
    if line = parseInt(lineStr)
      @get('activeTab')?.set('goToLine', line)
      @trackActivity()

  getFontSize: ->
    if (size = @get 'fontSize')
      return size

    size = $(".active .code-editor .CodeMirror-wrap:visible").css("font-size")

    # fall back to CSS size
    unless size
      return DEFAULT_FONT_SIZE

    parseInt(size)

  increaseFontSize: ->
    curSize = @getFontSize()

    @set 'fontSize', curSize+1

  decreaseFontSize: ->
    curSize = @getFontSize()

    @set 'fontSize', curSize-1

  resetFontSize: ->
    @set 'fontSize', null

  trackActivity: ->
    if !@get('trackActivityQueued') # Debounce so that we don't track excessively.
      window.setTimeout(=>
        pingerSocket = @get('pingerSocket')
        return unless pingerSocket && pingerSocket.get('started')
        @get('pingerSocket').ping()
        @set('trackActivityQueued', false)
      , 1000)
      @set('trackActivityQueued', true)
