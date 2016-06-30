klass = App.Path = Em.ArrayProxy.extend Em.SortableMixin,
  sortProperties: ['file', 'persisted', 'filename']

  expanded: false
  selected: false
  absolutePath: ''
  realPath: ''
  loadCount: 0
  directory: false
  size: 0
  editable: false
  new: false
  beingDeleted: false
  deleted: false
  showInSidebar: false

  init: ->
    @set 'content', Em.A() unless @get 'content'
    @_super.apply this, arguments

  persisted: (->
    !@get 'new'
  ).property 'new'

  name: (->
    if absolutePath = @get 'absolutePath'
      if absolutePath == "/"
        return "/"
      components = @constructor.pathToComponents(absolutePath)
      components[components.length - 1]
    else
      '~'
  ).property 'absolutePath'

  collabPath: (->
    if realPath = @get('realPath')
      return realPath
    @get('absolutePath')
  ).property 'absolutePath', 'realPath'

  lowerCaseName: (->
    if name = @get 'name'
      name.toLowerCase()
  ).property 'name'

  filename: (->
    App.Filename.create
      name: @get('lowerCaseName')
  ).property 'lowerCaseName'

  hidden: (->
    if name = @get 'name'
      name[0] == '.'
  ).property 'name'

  rootPath: (->
    this == App.get('router.ideSidebarController.rootPath')
  ).property 'App.router.ideSidebarController.rootPath'

  file: (->
    !@get 'directory'
  ).property 'directory'

  loading: (->
    @get('loadCount') > 0
  ).property 'loadCount'

  parentAbsolutePath: (->
    if absolutePath = @get 'absolutePath'
      absolutePath.split('/').slice(0, -1).join '/'
  ).property 'absolutePath'

  findByRelativePath: (path) ->
    if _.isString path
      if path.length == 0 || path == '/' || path == @get('absolutePath')
        return this
      # convert the given path to relative path
      path = path.replace @get('absolutePath')+'/', ''
      path = @constructor.pathToComponents(path)
    content = @get 'content'
    if found = content.findProperty 'name', path[0]
      found = found.findByRelativePath(path.slice 1) if path.length > 1
    found

  updateContent: (newContent) ->
    absolutePath = @get 'absolutePath'
    content = @get 'content'

    allPaths = App.get 'router.ideSidebarController.content'
    existingContentPaths = content.map (path) -> path.get 'absolutePath'

    addedContent = Em.A()
    removedContent = Em.A()

    _getAbsolutePathForItem = (name) ->
      _.chain([absolutePath, name]).compact().join('/').value()

    newContent.forEach (item) =>
      name = item[0]
      isDir = item[1]
      size = item[2]
      realPath = item[3]

      absolutePathForItem = _getAbsolutePathForItem(name)
      if existingContentPaths.contains absolutePathForItem
        path = this.findByRelativePath name
        if !isDir && path.get 'directory'
          path.set 'content', Em.A()
      else
        path = App.Path.create
          absolutePath: absolutePathForItem
        addedContent.push path
      path.setProperties
        directory: isDir
        size: size
        realPath: realPath

    newContentPaths = newContent.map (item) -> _getAbsolutePathForItem(item[0])
    content.forEach (path) ->
      unless newContentPaths.contains path.get('absolutePath')
        removedContent.push path unless path.get 'new'

    allPaths.removeObjects removedContent
    content.addObjects addedContent
    content.removeObjects removedContent

klass.reopenClass
  _create: klass.create

  create: ->
    path = klass._create.apply this, arguments
    unless path.get 'new'
      allPaths = App.get 'router.ideSidebarController.content'
      if allPaths
        absolutePath = path.get 'absolutePath'
        if absolutePath && existingPath = allPaths.findProperty 'absolutePath', absolutePath
          return existingPath
        allPaths.pushObject path
    path

  pathToComponents: (pathString) ->
    pathString.split '/'

# This is a workaround: Ember.compare() compares strings using localeCompare(),
# which unfortunately sorts 'foo_test.go' before 'foo.go'.
App.Filename = Em.Object.extend Em.Comparable,
  name: null

  compare: (a, b) ->
    aName = a.get('name')
    bName = b.get('name')

    return -1 if aName < bName
    return 1 if aName > bName
    return 0
