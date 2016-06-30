PluginBase = require './base'

GOPATH_ERROR = /not beneath any of these GOROOT\/GOPATH directories:\s?(.+)$/
NOTFOUND_ERROR = /command\s+not\s+found:/

klass = class Go extends PluginBase
  afterSave: (context)->
    opsSocket = context.opsSocket
    sidebar = context.sidebar
    pth = @path()

    if !pth || !opsSocket
      return
    cmd = [
      "goimports",
      "-w",
      pth.get('absolutePath')
    ]
    cwd = ''
    env = []
    @exec cmd, cwd, env, (err, cmdErr, stdout, stderr) =>
      @document.processErrMessage stderr
      if err || cmdErr
        @document.set 'clean', true
        return
      if sidebar
        sidebar.refreshTextFileContent pth

  supportsGoToDefinition: true
  goToDefinition: (context)->
    opsSocket = context.opsSocket
    sidebar = context.sidebar
    pth = @path()

    expandedPath = pth.get('absolutePath')
    unless context.noReadlink
      expandedPath = "$(readlink -f #{expandedPath})"

    if !pth || !opsSocket
      return
    cmd = [
      "oracle",
      "-format=json",
      "-pos=#{expandedPath}:##{@document.get("currentOffset")}",
      "definition"
    ]
    cwd = ''
    env = []
    @exec cmd, cwd, env, (err, cmdErr, stdout, stderr) =>
      if err || cmdErr
        if stderr
          @processOracleErr(context, stderr)
        return
      data = JSON.parse stdout
      if (def = data.definition) && (pos = def.objpos)
        match = pos.match(/^([^:]+):(\d+):(\d+)$/)
        if match
          filepath = match[1]
          line = match[2]
          cursor = match[3]
          pth = App.Path.create absolutePath: filepath
          if sidebar
            pos = {line: parseInt(line)-1, ch: parseInt(cursor)-1}
            sidebar.openPath pth, selections: [{anchor: pos, head: pos}]

  processOracleErr: (context, err)->
    err = err.trim()
    if m = err.match NOTFOUND_ERROR
      @handleError "For Go To Definition to work, <strong>gooracle</strong> must be installed.",
        title: "Oracle is not installed"
        url: "https://community.nitrous.io/docs/using-go-to-definition-with-go#not_installed"
        okText: 'Help'
      return
    if m = err.match GOPATH_ERROR
      # our symlink expanding may have broke
      unless context.noReadlink
        context.noReadlink = true
        @goToDefinition(context)
        return
      pth = @path()
      @handleError "This file is not inside your GOPATH or GOROOT paths: #{m[1]}.<br/><br/>For Go code tooling to work you must ensure <b>#{pth.get('absolutePath')}</b> is inside GOPATH or GOROOT.",
        title: "File is outside GOPATH/GOROOT"
        url: "https://community.nitrous.io/docs/using-go-to-definition-with-go#file_outside_gopath"
        okText: "Help"
      return

    console.log "Go To Definition error: ", err
    @handleSnackbarError "Go To Definition is unavailable."

App.CodePluginsManager.registerCodePlugin "golang", klass, ["go", "text/x-go"]
