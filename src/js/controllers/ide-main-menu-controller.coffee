#require '../components/ui-progress-component'
#require '../templates/ui-progress'

activeDocumentSet = (attr, val) ->
  if tab = App.get 'router.ideEditorController.activeTab'
    tab.set attr, val

App.IdeMainMenuController = Em.Controller.extend
  needs: ['ide', 'ideEditor', 'ideConsole', 'ideFindInProject', 'ideFileFinder', 'ideSidebar', 'ideGit']
  initialize: ->
    this._reloadUserUsage()

  reset: ->

  toggleBetaMode: ->
    if editorController = @get 'controllers.ideEditor'
      if editorController.get('beta')
        editorController.set 'autoCompleteBeta', false
        editorController.set 'beta', false
      else
        @get('controllers.ide').set('showBetaDialog', true)

  fileNew: ->
    if App.get('consoleFocused') && consoleController = @get 'controllers.ideConsole'
      consoleController.createTab()
    else if editorController = @get 'controllers.ideEditor'
      editorController.createTab()

  fileSave: ->
    if editorController = @get 'controllers.ideEditor'
      editorController.saveDocument editorController.get('activeTab')

  fileGoToFile: ->
    if controller = @get 'controllers.ideFileFinder'
      controller.showFindDialog()

  fileClose: ->
    if App.get('consoleFocused') && consoleController = @get 'controllers.ideConsole'
      consoleController.removeTab()
    else if editorController = @get 'controllers.ideEditor'
      editorController.removeTab()

  fileRefreshTree: ->
    if sidebarController = App.get 'router.ideSidebarController'
      sidebarController.refreshAll()

  findFind: ->
    activeDocumentSet 'findTrigger', true

  findFindNext: ->
    activeDocumentSet 'findNextTrigger', true

  findSelectNext: ->
    activeDocumentSet 'selectNextTrigger', true

  findFindPrevious: ->
    activeDocumentSet 'findPrevTrigger', true

  findFindInFiles: ->
    if controller = @get 'controllers.ideFindInProject'
      path = this.get('controllers.ideSidebar.rootPath')?.absolutePath
      controller.showFindDialog(path)

  findReplace: ->
    activeDocumentSet 'replaceTrigger', true

  findGoToDefinition: ->
    if editorController = @get 'controllers.ideEditor'
      editorController.goToDefinition editorController.get('activeTab')

  revealInSidebar: ->
    if editorController = @get 'controllers.ideEditor'
      path = editorController.get('activeTab.path')
      return unless path

      if sidebarController = App.get 'router.ideSidebarController'
        sidebarController.reveal path

  editGoToLine: ->
    if controller = @get 'controllers.ideEditor'
      controller.showGoToLineDialog()

  editFoldCode: ->
    activeDocumentSet 'foldCodeTrigger', true

  editUnfoldCode: ->
    activeDocumentSet 'unfoldCodeTrigger', true

  editToggleComment: ->
    activeDocumentSet 'toggleCommentTrigger', true

  editSetKeybindings: (type) ->
    if editorController = @get 'controllers.ideEditor'
      editorController.set 'keybindings', type

  editToggleAutoCloseBrackets: ->
    @_toggleEditorProperty 'autoCloseBrackets'

  editToggleRemoveTrailingWhitespaceOnSave: ->
    @_toggleEditorProperty 'removeTrailingWhitespaceOnSave'

  editSplitSelectionIntoLines: (type) ->
    activeDocumentSet 'splitSelectionIntoLinesTrigger', true

  editToggleAutocomplete: ->
    @_toggleEditorProperty 'autocomplete'

  windowFocusConsole: ->
    if doc = @get 'controllers.ideEditor.activeTab'
      doc.set 'focused', false
    if consoleSession = @get 'controllers.ideConsole.activeTab'
      consoleSession.set 'focused', true

  windowFocusEditor: ->
    if doc = @get 'controllers.ideEditor.activeTab'
      doc.set 'focused', true
    if consoleSession = @get 'controllers.ideConsole.activeTab'
      consoleSession.set 'focused', false

  windowSelectNextTab: ->
    if App.get('consoleFocused') && consoleController = @get 'controllers.ideConsole'
      consoleController.makeNextTabActive()
    else if editorController = @get 'controllers.ideEditor'
      editorController.makeNextTabActive()

  windowSelectPreviousTab: ->
    if App.get('consoleFocused') && consoleController = @get 'controllers.ideConsole'
      consoleController.makePreviousTabActive()
    else if editorController = @get 'controllers.ideEditor'
      editorController.makePreviousTabActive()

  windowToggleMinimizeConsole: ->
    App.toggleProperty 'consoleMinimized'
    if App.get('consoleMinimized')
      App.set 'consoleFullscreen', false
      @windowFocusEditor()
    else
      @windowFocusConsole()

  windowToggleFullScreenConsole: ->
    App.toggleProperty 'consoleFullscreen'
    App.set('consoleMinimized', false) if App.get('consoleFullscreen')
    window.setTimeout(=>
      @windowFocusConsole()
    , 50)

  windowHideFileTree: ->
    App.set 'fileTreeHidden', true

  windowShowFileTree: ->
    App.set 'fileTreeHidden', false

  windowHideActiveFiles: ->
    App.get('router.ideSidebarController')?.set('overrideActiveFilesPane', false)

  windowShowActiveFiles: ->
    @windowShowFileTree()
    App.get('router.ideSidebarController')?.set('overrideActiveFilesPane', true)

  viewSplitEditorPaneVertically: ->
    App.get('router.ideEditorController').splitActivePaneVertically()

  viewSplitEditorPaneHorizontally: ->
    App.get('router.ideEditorController').splitActivePaneHorizontally()

  viewCloseEditorPane: ->
    App.get('router.ideEditorController').closeActivePane()

  windowSelectTheme: (theme) ->
    if editorController = @get 'controllers.ideEditor'
      editorController.set 'theme', theme

  viewToggleLineNumbers: ->
    @_toggleEditorProperty 'showLineNumbers'

  viewSetRulerColumn: (column) ->
    if editorController = @get 'controllers.ideEditor'
      editorController.set 'rulerColumn', column

  helpNitrousReadme: ->
    if sidebarController = App.get 'router.ideSidebarController'
      sidebarController.openRepoReadme()

  viewToggleTrailingSpace: ->
    @_toggleEditorProperty 'showTrailingSpace'

  viewToggleWrapLines: ->
    @_toggleEditorProperty 'wrapLines'

  viewToggleHighlightLine: ->
    @_toggleEditorProperty 'highlightLine'

  viewToggleMatchBrackets: ->
    @_toggleEditorProperty 'matchBrackets'

  viewIncreaseFontSize: ->
    if editorController = @get 'controllers.ideEditor'
      editorController.increaseFontSize()

  viewDecreaseFontSize: ->
    if editorController = @get 'controllers.ideEditor'
      editorController.decreaseFontSize()

  viewResetFontSize: ->
    if editorController = @get 'controllers.ideEditor'
      editorController.resetFontSize()

  betaToggleAutoCompleteBeta: ->
    @_toggleEditorProperty 'autoCompleteBeta'

  gitCloneFromGitHub: ->
    if controller = @get 'controllers.ideGit'
      controller.showCloneFromGitHubDialog()

  showConfirmStopHostDialog: ->
    ui.showModal '#confirm-stop-host-dialog'

  closeConfirmStopHostDialog: ->
    ui.hideModal '#confirm-stop-host-dialog'

  stopHost: (hostSlug) ->
    url = "/hosts/#{hostSlug}/stop"
    ui.hideModal '#confirm-stop-host-dialog'
    ui.showModal '#stopping-host-dialog'
    Em.RSVP.Promise.resolve(
      Em.$.ajax(
        type: 'POST',
        url: "/api/v0/hosts/#{hostSlug}/stop",
        headers: { Authorization: "Bearer #{App.get 'token'}" }
      )).then((data) =>
        ui.hideModal '#stopping-host-dialog'
        @transitionToRoute '/'
        App.snackbar.post("Workstation #{hostSlug} stopped")
      , (jqxhr) =>
        ui.hideModal '#stopping-host-dialog'
        App.snackbar.postError(jqxhr.responseJSON, "Failed to stop workstation #{hostSlug}!")
      )

  _toggleEditorProperty: (property) ->
    if editorController = @get 'controllers.ideEditor'
      editorController.toggleProperty(property)

  _reloadUserUsage: ->
    Ember.run.later(this, (=>
      App.User.fetch().then (user) ->
        App.user.set 'usage_remaining', user.usage_remaining
        App.user.set 'usage_quota', user.usage_quota

      this._reloadUserUsage()
    ), 60*1000)
