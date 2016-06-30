App.ActiveFilesMonitor = klass = Em.Object.extend
  collabSocket: null
  username: null

  remoteFiles: null
  localFiles: null

  init: ->
    @_super.apply this, arguments

    collabSocket = @get 'collabSocket'

    # we join the global namespace so we receive broadcasted events
    collabSocket.send 'global', 'join', ''

    collabSocket.on 'activefiles|global', @handleActiveReceived.bind(this)
    collabSocket.on 'joined|global', @handleJoined.bind(this)
    collabSocket.on 'left|global', @handleLeft.bind(this)
    collabSocket.on 'disconnected|global', @handleLeft.bind(this)

    collabSocket.on 'reconnected', @handleReconnected.bind(this)

    @set 'remoteFiles', {}
    @set 'localFiles', {}
    @userMap = {}

    # refresh list
    @refresh()

  tabsDidChange: (allTabs)->
    hsh = {}
    for tab in allTabs
      pathObj = tab.get && tab.get('path')
      if pth = pathObj?.get?('absolutePath')
        hsh[pth] = true

    @set 'localFiles', hsh
    @propertyDidChange 'localFiles'

  handleActiveReceived: (data)->
    hsh = {}
    for id in Object.keys(data.sessions)
      unless id == "global"
        file = @fileFromNamespace(id)
        if file
          clients = []
          for cID in Object.keys(data.sessions[id].clients)
            client = data.sessions[id].clients[cID]
            @userMap[cID] = client.name

            unless client.name == @get("username")
              clients.push cID
          if clients.length
            hsh[file] = clients
    @set 'remoteFiles', hsh

  handleJoined: (msg)->
    @refresh()

  handleLeft: (msg)->
    @refresh()

  sortedFiles: (->
    localFiles = @get 'localFiles'
    remoteFiles = @get 'remoteFiles'

    allKeys = Object.keys(localFiles)
    for key in Object.keys(remoteFiles)
      if allKeys.indexOf(key) == -1
        allKeys.push key

    sortedKeys = allKeys.sort()
    sortedKeys.map (k)=>
      hasRemoteClients = false
      connIDs = []
      openedLocal = localFiles[k] || false
      if openedLocal
        connIDs.push @get 'collabSocket.connID'
      if (remote = remoteFiles[k])?.length
        hasRemoteClients = true
        connIDs = connIDs.concat remote

      clients = []
      for cID in connIDs.sort().reverse()
        uname = if cID == @get 'collabSocket.connID'
          @get 'username'
        else
          @userMap[cID]

        if clients.indexOf(uname) == -1
          clients.push(uname)

      {
        path: App.Path.create(absolutePath: k),
        clients: clients,
        openedLocal: openedLocal,
        hasRemoteClients: hasRemoteClients
      }
  ).property 'remoteFiles', 'localFiles'

  handleReconnected: ->
    @refresh()

  refresh: ->
    collabSocket = @get 'collabSocket'
    collabSocket.send App.get('container.slug'), "activefiles"

  fileFromNamespace: (namespace)->
    match = namespace.match(/^[^:]+:(.+)/)
    return unless match
    match[1]
