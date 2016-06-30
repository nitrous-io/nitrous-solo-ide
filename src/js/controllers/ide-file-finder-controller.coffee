App.IdeFileFinderController = Em.Controller.extend
  needs: ['ide', 'ideEditor', 'ideSidebar']

  opsSocketBinding: Em.Binding.oneWay 'controllers.ide.opsSocket'
  fileFinderDialog: null

  initialize: ->
    socket = @get 'opsSocket'
    socket.on 'file_find.output', _.bind(@onOutput, this)
    socket.on 'file_find.error', _.bind(@onError, this)
    socket.on 'file_find.completed', _.bind(@onCompleted, this)

  reset: ->
    @set 'fileFinderDialog', null
    socket = @get 'opsSocket'
    socket.off 'file_find.output'
    socket.off 'file_find.error'

  onOutput: (error, data) ->
    @get('fileFinderDialog')?.addResults(data.term, data.root, data.paths)

  onError: (error, data) ->
    dialog = @get 'fileFinderDialog'
    return unless dialog?

    # handle errors occurr before search begins
    if error
      dialog.set 'error', error

    # when a mid-stream error occurrs,
    # show current results and mark the search as complete
    if data.error
      dialog.searchComplete(data.term, data.root)

  onCompleted: (error, data) ->
    @get('fileFinderDialog')?.searchComplete(data.term, data.root)

  showFindDialog: (path) ->
    if !path?
      path = this.get('controllers.ideSidebar.rootPath')?.absolutePath
      if !path?
        path = App.get('container.homePath')
    @set 'fileFinderDialog', App.FileFinderDialog.create basePath: path

  startFind: (pattern, path) ->
    dialog = @get 'fileFinderDialog'
    socket = @get 'opsSocket'
    return if !dialog || !socket

    path = App.get('container.homePath') if not path?.length

    dialog.find pattern, path, =>
      @set 'findPattern', pattern
      @set 'findPath', path
      Ember.run.debounce this, this.socketFind, 500 # at most once per 0.5s

  socketFind: ->
    dialog = @get 'fileFinderDialog'
    socket = @get 'opsSocket'
    pattern = @get 'findPattern'
    path = @get 'findPath'
    if dialog && socket && pattern && path
      dialog.searchStart(pattern, path)
      socket.fileFind pattern, path, (err) ->
        if err
          dialog.set 'error', err
          return

  closeFindDialog: ->
    this.reset()
