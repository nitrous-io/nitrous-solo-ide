App.IdePathView = Em.View.extend App.IdeDragDropViewMixin,
  templateName: 'path'
  tagName: 'li'
  path: null
  droppable: false
  classNameBindings: ['path.selected', 'path.expanded', 'droppable']
  attributeBindings: 'draggable'

  didInsertElement: ->
    @_super()
    @showInSidebar()

  showInSidebar: (->
    return unless @get('path.showInSidebar')
    @set 'path.showInSidebar', false
    $this = @$()
    topPos = $this.position().top
    par = $this.parents(".tree")
    parHeight = par.height() / 2
    targetTop = topPos-parHeight
    return if par.scrollTop >= targetTop
    par.scrollTop(targetTop)
  ).observes 'path.showInSidebar'

  click: (event) ->
    this._selectFile event
    controller = @get 'controller'
    path = @get 'path'
    unless path.get 'editable'
      controller.openPath path, source: 'filetree'
    sidebarView = this.nearestOfType App.IdeSidebarView
    sidebarView.hideContextMenu()

  contextMenu: (event) ->
    this._selectFile event
    path = @get 'path'
    sidebarView = this.nearestOfType App.IdeSidebarView
    sidebarView.showContextMenu event, path

  draggable: (->
    if @get('path')?.get 'rootPath'
      'false'
    else
      'true'
  ).property 'path.rootPath'

  dragStart: (event) ->
    @_super event
    path = @get 'path'
    path.set 'expanded', false
    path.set 'selected', false
    @get('controller').set 'currentlyDraggedPath', path

  dragEnter: (event) ->
    @_super event
    controller = @get 'controller'
    previousDroppable = controller.get 'currentDroppable'
    if previousDroppable && !previousDroppable.isDestroyed
      previousDroppable.set 'droppable', false
    if droppable = this._getDroppable()
      droppable.set 'droppable', true
      controller.set 'currentDroppable', droppable

  drop: (event) ->
    @_super event
    if droppable = this._getDroppable()
      droppable.set 'droppable', false
      path = droppable.get 'path'
      @get('controller').moveDraggedPathTo path
    @get('controller').set 'currentlyDraggedPath', null

  _selectFile: (event) ->
    this._preventDefaultAndPropagation event
    controller = @get 'controller'
    path = @get 'path'
    if previouslySelectedPath = controller.get 'currentlySelectedPath'
      previouslySelectedPath.set 'selected', false
    if path.get 'file'
      path.set 'selected', true
      controller.set 'currentlySelectedPath', path

  _getDroppable: ->
    parentView = null
    path = @get 'path'
    if draggedPath = @get('controller').get 'currentlyDraggedPath'
      # if current path is not a directory
      # choose its parent (directory) as the drop target
      unless path.get 'directory'
        parentView = this.nearestOfType App.IdePathView
        path = parentView.get 'path'
      # should not drop to dragged path or its parent itself
      absolutePath = path.get 'absolutePath'
      unless (absolutePath == draggedPath.get('absolutePath')) || (absolutePath == draggedPath.get('parentAbsolutePath'))
        parentView || this
