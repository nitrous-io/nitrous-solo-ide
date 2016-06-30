LINE_NO_REGEX = /\s*:(\d+)\s*$/

App.IdeFileFinderDialogView = App.IdeModalDialogView.extend
  templateName: 'ide/file-finder-dialog'
  elementId: 'ide-file-finder-dialog-view'
  contentBinding: 'controller.fileFinderDialog'

  pollerKey: null

  didInsertElement: ->
    @get('controller').initialize()

  viewDidAppear: ->
    @_super()
    this.setupPoller()

  viewDidDisappear: ->
    @_super()
    @set('stopPoller', true)
    @get('controller.controllers.ideEditor.activeTab')?.set 'focused', true

  click: (e) ->
    if $(e.target).is(@$())
      @hide()
    e.stopPropagation()

  keyDown: (e) ->
    suppress = ->
      e.preventDefault()
      e.stopPropagation()
    switch e.which
      when 27 # escape
        @hide()
      when 38 # up
        suppress()
        @get('content')?.decrementIndex()
      when 40 # down
        suppress()
        @get('content')?.incrementIndex()
      when 10, 13
        suppress()
        if path = @get('content.selectedFile.absolutePath')
          this.didClickResult(path)
        else
          # user may want to navigate in file
          if line = @get 'patternLineNumber'
            @set('controller.controllers.ideEditor.activeTab.goToLine', line)
            @hide()

  setupPoller: ->
    @set('stopPoller', false)
    @set 'pollerKey', Ember.run.later(this, (=>
      this.poller()
      this.setupPoller() unless @get('stopPoller')
    ), 200)

  patternForSearch: (->
    return unless @get('content.pattern')
    replaced = @get('content.pattern').replace(LINE_NO_REGEX, "")
    return @get('content.pattern') if replaced == ""
    replaced
  ).property 'content.pattern'

  patternLineNumber: (->
    if (m = @get('content.pattern')?.match(LINE_NO_REGEX))
      return parseInt(m[1])
  ).property 'content.pattern'

  poller: ->
    nextSearch = @get('patternForSearch')
    if nextSearch != @get('content.currentSearch')
      @get('controller').startFind nextSearch, @get('content.basePath')
      return unless @get('content')
      @set 'content.currentSearch', nextSearch

  didClickResult: (filename) ->
    # filename will be relative to home directory
    path = App.Path.create absolutePath: filename
    if sidebar = @get 'controller.controllers.ideSidebar'
      opts = {
        done: =>
          this.hide()
        source: 'filefinder'
      }
      if line = @get 'patternLineNumber'
        pos = {line: line-1, ch: 0}
        opts.selections = [{anchor: pos, head: pos}]
      sidebar.openPath path, opts

