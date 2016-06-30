require './base'

klass = class GlobalRuby
  NITROUS_IMAGE_CMD = "ctags -f .ruby-tags -R --languages=ruby --exclude=.git --exclude=log --exclude=tmp . $(LD_LIBRARY_PATH=$(dirname $(rbenv which ruby))/../lib bundle list --paths)"
  CMD = "ctags -f .ruby-tags -R --languages=ruby --exclude=.git --exclude=log --exclude=tmp . $(bundle list --paths)"

  SOFTWARE_REQUIREMENTS = "1"
  SOFTWARE_REQUIRED = "silversearcher-ag exuberant-ctags"

  constructor: () ->
    @activeTimers = {}

  setOption: (key, value)->
    @[key] = value

  afterInitialize: ->
    return if @container?.get('metadata.softwareRequirements') == SOFTWARE_REQUIREMENTS

    return if @installingSoftware
    @installingSoftware = true
    cmd = [
      "sudo apt-get install -y #{SOFTWARE_REQUIRED}"
    ]
    @opsSocket.loginrun cmd, '', [], (err, cmdErr, stdout, stderr) =>
      if stdout.match(/is already the newest version/) || stdout.match(/Setting up/)
        @container?.setMetadata(softwareRequirements: SOFTWARE_REQUIREMENTS)

        for plugin in (App.CodePluginsManager.activePlugins['ruby'] || [])
          plugin.triggerCtagsUpdate()

        console.log "#{SOFTWARE_REQUIRED} was installed", stdout
      else
        App.postError('An error occurred installing ag/ctags.')
        console.log "#{SOFTWARE_REQUIRED} was not installed", stderr, stdout

      @installingSoftware = false

  unload: ->
    if @activeTimers
      for path, timer of @activeTimers
        window.clearTimeout timer

  triggerCtagsUpdate: (parent)->
    return unless @opsSocket

    return if @activeTimers[parent]
    ctagsCmd = CMD
    if @container.image.match(/nitrous/) || @container?.get('metadata.nitrousRuby')
      ctagsCmd = NITROUS_IMAGE_CMD

    @activeTimers[parent] = window.setTimeout =>
      cmd = [
        "cd #{parent} && #{ctagsCmd}"
      ]
      @opsSocket.loginrun cmd, parent, [], (err, cmdErr, stdout, stderr) =>
        @activeTimers[parent] = null

        if cmdErr || err
          console.log "Error invoking ctags update:", err, cmdErr, stderr, stdout
          return

        for plugin in (App.CodePluginsManager.activePlugins['ruby'] || [])
          plugin.ctagsUpdated()
    , 50

App.CodePluginsManager.registerGlobalPlugin "ruby", klass
