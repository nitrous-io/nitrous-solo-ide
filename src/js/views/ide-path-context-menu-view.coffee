App.IdePathContextMenuView = Em.View.extend
  templateName: 'ide/path-context-menu'
  elementId: 'ide-path-context-menu-view'
  classNames: ['ui', 'dropdown']

  path: null

  willDestroyElement: ->
    @_super()
    @set 'path', null

  show: (event, path) ->
    @set 'path', path
    offsetX = 0
    offsetY = -32
    left = event.clientX + offsetX
    top = event.clientY + offsetY

    @$('.dropdown-menu').css
      top: if top > 0 then top else 0
      left: if left > 0 then left else 0

    ui.openDropdown(event, @$())

  hide: ->
    ui.clearDropdowns()

  actions:
    didClickOpen: ->
      path = @get 'path'
      @get('controller').openPath path

    didClickRefresh: ->
      path = @get 'path'
      @get('controller').refresh path

    didClickFindInFolder: ->
      path = @get 'path'
      @get('controller').findInFolder path

    didClickNewFile: ->
      path = @get 'path'
      @get('controller').newPath path, false

    didClickNewFolder: ->
      path = @get 'path'
      @get('controller').newPath path, true

    didClickUploadFiles: ->
      path = @get 'path'
      @get('controller').showUploadDialog path

    didClickSetFolderAsRoot: ->
      path = @get 'path'
      @get('controller').setPathAsRoot path

    didClickRename: ->
      path = @get 'path'
      @get('controller').renamePath path

    didClickDelete: ->
      path = @get 'path'
      @get('controller').confirmDelete path

    didClickDownloadFile: ->
      path = @get 'path'
      @get('controller').downloadPath path
