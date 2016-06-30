App.IdeSidebarController = Em.ArrayController.extend
  needs: ['ide', 'ideFindInProject', 'ideEditor']

  homePath: null # home (~/) path
  rootPath: null # current root path in the sidebar
  content:  null # array of all path objects
  uploadDialog: null
  confirmDeletePathDialog: null

  opsSocketBinding: Em.Binding.oneWay 'App.router.ideController.opsSocket'
  opsSocketReadyBinding: Em.Binding.oneWay 'opsSocket.started'
  opsSocketNotReady: Em.computed.not 'opsSocketReady'

  activeFilesMonitorBinding: Em.Binding.oneWay 'App.router.ideController.activeFilesMonitor'

  repositoryBinding: Em.Binding.oneWay 'App.router.indexontroller.repository'

  hiddenFilesVisible: false
  overrideActiveFilesPane: null

  currentlySelectedPath: null

  # attributes used for drag&drop
  currentlyDraggedPath: null
  currentDroppable: null

  initialize: ->
    @set 'homePath', homePath = App.Path.create absolutePath: App.get('container.homePath'), directory: true
    @set 'content', Em.A([homePath])
    @set 'rootPath', App.Path.create absolutePath: App.get('container.rootPath'), directory: true

  reset: ->
    @set 'homePath', null
    @set 'rootPath', null
    @set 'content', null
    @set 'uploadDialog', null
    @set 'currentlyDraggedPath', null
    @set 'currentDroppable', null
    if socket = @get 'opsSocket'
      socket.off 'dirChanged.output'

  onDirChanged: (error, absolutePathString) ->
    this.refreshPath absolutePathString

  opsSocketDidStartForTheFirstTime: (->
    if @get 'opsSocket.startedFirstTime'
      Em.run.next =>
        socket = @get 'opsSocket'
        socket.on 'dirChanged.output', _.bind(@onDirChanged, this)
        this.openPath @get('rootPath')
        unless App.get('container.metadata.readmeOpened')
          this.openRepoReadme()

        @restoreOpenTabs()
  ).observes 'opsSocket.startedFirstTime'

  restoreOpenTabs: ->
    if openTabs = App.get('container.userData.openTabs')
      index = 0
      for tab in openTabs
        if tab.readme
          this.openRepoReadme active: tab.active, index: index
        else if tab.path
          pth = App.Path.create absolutePath: tab.path, directory: false
          this.openPath pth,
            error: false
            active: tab.active
            index: index
            scrollPosition: tab.scrollPosition
            selections: tab.selections
        index++

  openRepoDir: ->
    workspacePath = App.Path.create absolutePath: 'workspace', directory: true
    this.openPath workspacePath, error: false
    repoPath = App.Path.create absolutePath: "workspace/#{@get('repository.shortName')}", directory: true
    this.openPath repoPath, error: false

  openRepoReadme: (settings = {}) ->
    App.get('container').setMetadata({readmeOpened: true})

    if codeDir = @get('controllers.ide.codeDir')
      homePath = @get('homePath.absolutePath')

      dirPath = App.Path.create absolutePath: "#{homePath}/code", directory: true
      this.openPath dirPath, error: false

      codeDirPath = App.Path.create absolutePath: "#{homePath}/code/#{codeDir}", directory: true
      this.openPath codeDirPath, error: false

      # Try to open one of these readme files.
      readmes = ['README.nitrous.md', 'README.md', 'README.markdown', 'README']
      processingIdx = 0

      tryNextReadme = (errMsg) =>
        processingIdx = processingIdx + 1
        if processingIdx < readmes.length
          openReadme(readmes[processingIdx])

      openReadme = (readme) =>
        path = "#{homePath}/code/#{codeDir}/#{readme}"
        readmePath = App.Path.create absolutePath: path, directory: false
        this.openPath readmePath,
          error: tryNextReadme
          active: settings.active
          index: settings.index

      openReadme(readmes[0])

      return

    if (readme_url = App.get('container.env.NITROUS_README_URL'))
      editorController = @get('controllers.ideEditor')
      tab = editorController.createTab(
        content: readme_url
        path: readme_url
        active: settings.active
        index: settings.index
        title: 'README'
        readme: true
      , App.Iframe)

  # settings options:
  #   done: callback (document)
  #   error: callback (errorMessage)
  openPath: (path, settings = {}) ->
    return if path.get('loading') || !@get('opsSocketReady')

    if settings.error != false && typeof settings.error != 'function'
      settings.error = (err) ->
        message = switch err
          when 'aio:file_too_large'
            'Cannot open the selected file because it is too large.'
          else
            'Cannot open the selected file.'
        App.postError message

    if path.get 'directory'
      path.set 'expanded', !path.get('expanded')
      if path.get 'expanded'
        this.fetchFileList path
      else
        this.unwatchDir path
    else
      editorController = @get('controllers.ideEditor')
      if doc = editorController.findProperty 'path', path
        unless settings.active == false
          editorController.makeTabActive doc

        if (selections = settings.selections) && (selOne = selections[0])
          doc.set 'goToLine', {line: selOne.anchor.line, cursor: selOne.anchor.ch}
        if settings.done
          settings.done(doc)
      else
        this.fetchFileContent path, settings

  downloadPath: (path) ->
    if !path.get('loading')
      container = App.get('container')
      container.requestToken(["download"]).then (tokenResp) =>
        downloadFrame = $('<iframe></iframe>')
        downloadFrame.css 'display', 'none'
        downloadFrame.attr 'src', @downloadURL(container, path.get('absolutePath'), tokenResp.token)
        $('body').append downloadFrame
        window.setTimeout(->
          downloadFrame.remove()
        , 5000)
      , (jqxhr) ->
        App.postError(jqxhr.responseJSON, 'Could not download file, please try again.')

  downloadURL: (container, path, token) ->
    freighterdUrl = container.get 'freighterdUrl'
    cid = container.get 'cid'
    "https://#{freighterdUrl}/containers/#{cid}/download?path=#{path}&token=#{token}"

  unwatchDir: (path) ->
    opsSocket = @get 'opsSocket'
    opsSocket.unwatchDir path.get('absolutePath')

  reveal: (path) ->
    return unless path.get
    origPath = path
    while parent = path.get 'parentAbsolutePath'
      path = App.Path.create absolutePath: parent, directory: true
      unless path.get 'expanded'
        @openPath path
    origPath.set 'showInSidebar', true
    if previouslySelectedPath = @get 'currentlySelectedPath'
      previouslySelectedPath.set 'selected', false
    origPath.set 'selected', true
    @set 'currentlySelectedPath', origPath

  fetchFileList: (path) ->
    opsSocket = @get 'opsSocket'
    path.incrementProperty 'loadCount'
    opsSocket.fetchFileList path.get('absolutePath'), (err, absolutePath, content) ->
      path.decrementProperty 'loadCount'
      if err
        path.set 'expanded', false
      else
        path.updateContent content

  # reloads document content of a tab with a given path from server
  # this is for operations where we modified content of the file on the server
  # e.g. because of running gofmt/goimports on the code, and we want those
  # changes be reflected in the editor
  refreshTextFileContent: (path, settings = {}) ->
    opsSocket = @get 'opsSocket'
    path.incrementProperty 'loadCount'
    editorController = @get('controllers.ideEditor')

    opsSocket.fetchFileContent path.get('absolutePath'), (err, absolutePath, contentType, content) =>
      path.decrementProperty 'loadCount'
      if err
        if settings.error
          settings.error(err)
        return

      editorController = @get('controllers.ideEditor')
      if doc = editorController.findProperty 'path', path
        doc.set 'replaceContentTrigger', content
      if settings.done
        settings.done(tab)

  fetchFileContent: (path, settings = {}) ->
    opsSocket = @get 'opsSocket'
    path.incrementProperty 'loadCount'
    editorController = @get('controllers.ideEditor')

    opsSocket.fetchFileContent path.get('absolutePath'), (err, absolutePath, contentType, content) =>
      path.decrementProperty 'loadCount'
      if err
        if err == 'aio:file_is_oversized_image'
          container = App.get('container')
          container.requestToken(['download']).then (tokenResp) =>
            tab = editorController.createTab(
              content: @downloadURL(container, path.get('absolutePath'), tokenResp.token)
              path: path
              active: settings.active
              index: settings.index
              selections: settings.selections
              scrollPosition: settings.scrollPosition
            , App.Image)
            if settings.done
              settings.done(tab)
          return

        if settings.error
          settings.error(err)
        return

      tabClass = if contentType?.match /^image/ then App.Image else App.Document
      tab = editorController.createTab(
        content: content
        path: path
        contentType: contentType
        active: settings.active
        index: settings.index
        selections: settings.selections
        scrollPosition: settings.scrollPosition
      , tabClass)
      if settings.done
        settings.done(tab)

  refresh: (path) ->
    if path.get('directory') && path.get('expanded')
      delay = 0

      for subpath in path.get 'arrangedContent'
        if subpath.get('directory') && subpath.get('expanded')
          delay += @constructor.REFRESH_DELAY
          ((controller, subpath, delay) ->
            window.setTimeout ->
              controller.refresh subpath
            , delay
          )(this, subpath, delay)

      unless path.get 'loading'
        this.fetchFileList path

  refreshPath: (pathString) ->
    homePath = @get 'homePath'
    rootPath = @get 'rootPath'
    if path = (homePath.findByRelativePath(pathString) || rootPath.findByRelativePath(pathString))
      this.refresh path

    if fileMon = @get 'activeFilesMonitor'
      fileMon.refresh()

  refreshAll: ->
    this.refresh @get('rootPath')

  findInFolder: (path) ->
    controller = @get 'controllers.ideFindInProject'
    if controller
      controller.showFindDialog(path.absolutePath)

  setHomeAsRoot: ->
    @set 'rootPath', @get('homePath')
    @set 'rootPath.expanded', true
    @refresh @get 'rootPath'

  setPathAsRoot: (path) ->
    @set 'rootPath', path

  rootPathDidChange: (->
    val = @get 'rootPath'
    return if App.get('container.rootPath') == val
    return if App.get('container.metadata.rootPath') == val
    App.get('container').setMetadata({rootPath: val.get 'collabPath'})
  ).observes 'rootPath'

  newPath: (path, directory) ->
    this.openPath path if !path.get 'expanded'
    newPath = App.Path.create
      absolutePath: "#{path.get('absolutePath')}/__aio_untitled_path__"
      new: true
      editable: true
      directory: directory
    path.addObject newPath

  saveNewPath: (path, name) ->
    if parentPath = @findParentPath(path)
      parentAbsolutePath = path.get 'parentAbsolutePath'
      opsSocket = @get 'opsSocket'
      absolutePath = _.chain([parentAbsolutePath, name]).compact().join('/').value()

      callback = (err) =>
        if err
          # TODO: Freighter should be returning a proper error code for file exists.
          # Revisit after #381 is merged.
          errMsg = if err.match /file exists/
            "\"#{name}\" already exists. Please enter a different filename."
          else
            "Error occurred while trying to save the file."
          App.postError errMsg
        path.set 'new', false # temp paths with 'new: false' get removed on refresh
        this.refresh parentPath

      if path.get 'directory'
        opsSocket.makeDirectory absolutePath, callback
      else
        opsSocket.writeNewFile absolutePath, '', callback

    @get('controllers.ideEditor').trackActivity()

  cancelNewPath: (path) ->
    if parentPath = @findParentPath(path)
      parentPath.get('content').removeObject path

  renamePath: (path) ->
    path.set 'editable', true
    @get('controllers.ideEditor').trackActivity()

  # apply rename operations to path
  # - path: the path object that we want to rename
  # - newPath: the path object / new name of the path.
  # - isDrag: if true, newPath will be the new path object that we drag the
  # path into a.k.a new parent path
  applyRenamedPath: (path, newPath, isDrag) ->
    if typeof newPath == "string"
      return this.resetRenamedPath path if newPath == path.get 'name'
    if isDrag && !(newPath instanceof App.Path)
      return console.warning("expected a App.Path object")
    if !isDrag && !(typeof newPath == "string")
      return console.warning("expected a path string")

    rootPath = @get('rootPath')
    parentAbsolutePath = path.get 'parentAbsolutePath'
    # current directory that hold the path
    parentPath = rootPath.findByRelativePath parentAbsolutePath
    return unless parentPath

    opsSocket = @get 'opsSocket'
    currentPathName = path.get 'name'

    if isDrag
      # if this is a drag operation, newPath is going to be the path that we drag
      # the file into, while the name of the file will be kept
      newParentPath = newPath.get('absolutePath')
      newPathName = currentPathName
    else
      # otherwise, this is the rename operation, which the parentPath will be
      # kept and the file will have a new name
      newParentPath = parentAbsolutePath
      newPathName = newPath

    currentAbsolutePath = this._makeAbsolutePath parentAbsolutePath, currentPathName
    newAbsolutePath = this._makeAbsolutePath newParentPath, newPathName

    path.incrementProperty 'loadCount'
    opsSocket.rename currentAbsolutePath, newAbsolutePath, (err) =>
      if err
        if err == 'aio:name_taken'
          App.set 'flashMessage', { type: 'error', text: "The name “#{newPathName}” is already taken. Please choose a different name." }
        else
          App.set 'flashMessage', { type: 'error', text: 'Rename failed.' }
      else
        path.set 'absolutePath', newAbsolutePath

      path.decrementProperty 'loadCount'
      path.set 'editable', false

      this.refresh parentPath
      this.refresh newPath if isDrag

  resetRenamedPath: (path) ->
    path.set 'editable', false

  showUploadDialog: (path) ->
    path ?= @get 'rootPath'
    @set 'uploadDialog', App.UploadDialog.create path: path

  beginUpload: ->
    uploadDialog = @get 'uploadDialog'
    if uploadDialog && uploadDialog.get('length')
      container = App.get('container')
      container.requestToken(["upload"]).then (tokenResp) =>
        uploadDialog.set 'uploading', true
        uploadDialog.set 'authToken', tokenResp.token
        uploadDialog.forEach (upload) ->
          upload.submit()
      , (jqxhr) ->
          App.postError(jqxhr.responseJSON, 'Could not upload files, please try again.')
    else
      @set 'uploadDialog', null

  didFinishAnUpload: (path) ->
    if path
      path = App.Path.create absolutePath: path
      this.refreshPath path.get('parentAbsolutePath')
    uploadDialog = @get 'uploadDialog'
    if uploadDialog && uploadDialog.get 'completed'
      #Mp.track Mp.EventIDEUserUploadedFile
      uploadDialog.set('hide', true)
      @set 'uploadDialog', null

  confirmDelete: (path) ->
    @set 'confirmDeletePathDialog', App.ConfirmDeletePathDialog.create path: path
    @get('controllers.ideEditor').trackActivity()

  delete: (path) ->
    return if path == @get 'rootPath'
    deleteMethod = if path.get('directory') then 'deleteDir' else 'deleteFile'
    opsSocket = @get 'opsSocket'
    parentPath = @findParentPath path
    path.set 'beingDeleted', true
    path.incrementProperty 'loadCount'

    opsSocket[deleteMethod] path.get('absolutePath'), (err) =>
      if err
        path.decrementProperty 'loadCount'
        path.set 'beingDeleted', false
      else
        path.set 'deleted', true
        if parentPath
          parentPath.get('content').removeObject path
        # TODO: not strictly necessary but, remove all children paths recursively from 'content' too?
        this.get('content').removeObject path

  moveDraggedPathTo: (path) ->
    draggedPath = @get 'currentlyDraggedPath'
    absoluteDroppablePath = path.get 'absolutePath'
    #expand the droppable path
    path.set 'expanded', true
    this.applyRenamedPath draggedPath, path, true
    @set 'currentlyDraggedPath', null
    @set 'currentDroppable', null

  _makeAbsolutePath: (parentAbsolutePath, fileName) ->
    _.chain([parentAbsolutePath, fileName]).compact().join('/').value()

  showActiveFilesPane: (->
    if (override = @get 'overrideActiveFilesPane') != null
      return override

    return @get('activeFilesMonitor')?.get('sortedFiles').any (file)->
      file.hasRemoteClients
  ).property 'overrideActiveFilesPane', 'activeFilesMonitor.sortedFiles'

  findParentPath: (path)->
    rootPath = @get 'rootPath'
    parentAbsolutePath = path.get 'parentAbsolutePath'
    return rootPath.findByRelativePath parentAbsolutePath

App.IdeSidebarController.reopenClass
  REFRESH_DELAY: 200
