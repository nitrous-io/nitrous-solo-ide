App.IdeSidebarActiveFilesView = Em.View.extend
  templateName: 'sidebar-active-files'
  elementId: 'ide-sidebar-active-files-view'

  activeFilesMonitorBinding: Em.Binding.oneWay 'controller.activeFilesMonitor'

  files: (->
    f = @get 'activeFilesMonitor.sortedFiles'
    return unless f
    ret = f.map (file)=>
      clients = []
      for username in file.clients
        res = @findUser(username)
        if res
          clients.push res
      {
        clients: clients,
        path: file.path,
        openedLocal: file.openedLocal
      }
    ret
  ).property 'activeFilesMonitor.sortedFiles', 'App.container.collaborators'

  findUser: (username)->
    if App.get('user.username') == username
      return App.get 'user'

    App.get('container').get('collaborators')?.findBy('username', username)

  actions:
    openPath: (file)->
      @get('controller').openPath(file.path)

