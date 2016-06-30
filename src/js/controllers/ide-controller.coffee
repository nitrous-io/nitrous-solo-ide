containerStoppedMessage = 'Project is not running. Please start your project first.'
hostStoppedMessage = 'Workstation is not running. Please start your workstation first, then start your project.'
resumingSessionMessage = 'Resuming your previous session...'
hostRestartingMessage = 'Workstation resuming, please wait...'
containerRestartingMessage = 'Resuming your project, please wait...'
freighterFeaturesRetry = 3000 # 3s
autoShutdownUser = 'host-provisioner' # username of system user that initiates auto-shutdown

App.IdeController = Em.ObjectController.extend
  queryParams: ['codeDir']
  needs: ['ideFindInProject', 'ideFileFinder', 'ideGit']

  codeDir: null # directory where project code lives under ~/code.

  opsSocket: null
  collabSocket: null
  collabEnabled: true

  hostStarted: false
  hostRestarted: false
  containerStarted: false
  containerRestarted: false

  resumingSession: false

  repository: null
  errorDialog: null
  showBetaDialog: null
  resumeSessionDialog: null
  startProjectDialog: null

  opsTimeoutAlert: null
  opsConnectionGracePeriod: 15 * 1000 # TODO: This should come from a KeyValue object from the server-side
  opsConnectionLost: false

  opsSocketReadyBinding: Em.Binding.oneWay 'opsSocket.started'
  opsSocketNotReady: Em.computed.not 'opsSocketReady'

  collabSocketReadyBinding: Em.Binding.oneWay 'collabSocket.started'
  collabSocketNotReady: Em.computed.not 'collabSocketReady'

  ideSocketsReady: (->
    return false if !@get('opsSocketReady')

    if @get('collabEnabled')
      return @get('collabSocketReady')

    return true
  ).property 'opsSocketReady', 'collabSocketReady', 'collabEnabled'

  ideSocketsNotReady: Em.computed.not 'ideSocketsReady'

  initialize: ->
    if container = @get 'content'
      # TODO fix once chrome app supports www
      if window.location.hostname.match(/^pro\./) && !App.get('chromeApp')
        App.postError "We are changing our default domain from pro.nitrous.io to www.nitrous.io. Please login and switch to www.nitrous.io"

      router = App.get 'router'
      router.get('ideLayoutController').initialize()
      router.get('ideMainMenuController').initialize()
      router.get('ideSidebarController').initialize()
      router.get('ideEditorController').initialize()
      router.get('ideConsoleController').initialize()
      router.get('ideGitController').initialize()

      PubSub.subscribe 'error.message', (msg, data) =>
        @set('errorDialog', data)

      App.CodePluginsManager.setAvailableOption 'container', container

      @set 'opsSocket', opsSocket = App.OpsSocket.create(container: container)
      opsSocket.connect()

      App.set 'eventsSocket', evSocket = App.EventsSocket.create()
      evSocket.connect()

      pingerSocket = App.PingerSocket.create
        hostId: container.get('host_id')
        pingWhenVisible: false
      App.set 'pingerSocket', pingerSocket
      pingerSocket.connect()

      @loadFreighterFeatures(container)

      ['container.stopped', 'container.restarted', 'container.reconfigured'].forEach (evt) =>
        evSocket.on evt, (data) =>
          if @get('content.id') == data?.container?.id
            App.get('container').setProperties(data.container)
            if data.config
              App.get('container').set('config', data.config)

      evSocket.on 'host.started', (data) =>
        @set('hostStarted', true)

      evSocket.on 'host.restarted', (data) =>
        @set('resumingSession', true)
        @set('hostRestarted', true)
        @set('resumeSessionDialog', @resumeSessionErrDialog(resumingSessionMessage))

        @startContainer().then =>
          @set('containerStarted', true)
        , (jqxhr) =>
          @set('errorDialog', @containerStoppedErrDialog())

      evSocket.on 'host.disk_almost_full', (data) =>
        App.snackbar.post "Disk is almost full. Please remove any unnecessary files or upgrade your plan."

      evSocket.on 'container.started', (data) =>
        if @get('content.id') == data?.container?.id
          @set('containerStarted', true)
          App.snackbar.post "Project started, resuming session..."

      evSocket.on 'container.restarted', (data) =>
        if @get('content.id') == data?.container?.id
          @set('containerRestarted', true)
          App.snackbar.post "Project restarted, resuming session..."

      evSocket.on 'container.stopped', (data) =>
        # Don't interrupt auto start container for user on host restart scenario.
        return if @resumingSession

        return if !data || !data.container
        container = data.container
        return if @get('content.id') != container.id

        # Find out why the container was stopped - it could be due to:
        # 1. user stopping their own container / host,
        # 2. owner stopping container / host, current user is a collaborator, or
        # 3. host was auto-shutdown by us.
        initiator = data.initiated_by?.username
        if initiator == autoShutdownUser
          @set('startProjectDialog', App.StartProjectDialog.create())
        else
          @set('errorDialog', @containerStoppedErrDialog())

      evSocket.on 'container.reconfigured', (data) =>
        if @get('content.id') == data?.container?.id
          App.snackbar.post "Project reconfigured, reconnecting..."

      ['collaborator.added', 'collaborator.removed'].forEach (evt) =>
        evSocket.on evt, (data) =>
          if @get('content.id') == data?.container?.id
            App.get('container').loadCollaborators()

  reset: ->
    if opsSocket = @get 'opsSocket'
      opsSocket.disconnect()
      opsSocket.destroy()

    router = App.get 'router'
    router.get('ideConsoleController').reset()
    router.get('ideEditorController').reset()
    router.get('ideSidebarController').reset()
    router.get('ideMainMenuController').reset()
    router.get('ideLayoutController').reset()

    @set 'opsSocket', null
    @set 'repository', null
    @set 'content', null
    @set 'errorDialog', null
    @set 'resumeSessionDialog', null
    @set 'startProjectDialog', null

  validateHostAndContainerState: ->
    if App.container.host.state != 'running'
      switch App.container.host.state
        when 'stopped'
          @startHostAndContainer()
        when 'restarting'
          @set('resumeSessionDialog', @resumeSessionErrDialog(hostRestartingMessage))
        else
          @set('errorDialog', @hostStoppedErrDialog())
    else if App.container.state != 'running'
      switch App.container.state
        when 'stopped'
          @resumeContainer()
        when 'restarting'
          @set('resumeSessionDialog', @resumeSessionErrDialog(containerRestartingMessage))
        else
          @set('errorDialog', @containerStoppedErrDialog())

  resumeContainer: ->
    @set('resumeSessionDialog', @resumeSessionErrDialog(resumingSessionMessage))
    @startContainer().then =>
      @set('containerStarted', true)
    , (jqxhr) =>
      @set('errorDialog', @containerStoppedErrDialog())

  startHostAndContainer: ->
    @set('resumeSessionDialog', @resumeSessionErrDialog(resumingSessionMessage))
    @startHost().then =>
      ###
      Even though host and container state values are set to true on
      receiving the relevant event, we additionally set these values
      on successful POST requests so that we don't miss the state
      changes if for some reason the event is not received.
      ###
      @set('hostStarted', true)
      @startContainer().then =>
        @set('containerStarted', true)
      , (jqxhr) =>
        @set('errorDialog', @containerStoppedErrDialog())
    , (jqxhr) =>
      @set('errorDialog', @hostStoppedErrDialog())

  startHost: ->
    Em.RSVP.Promise.cast Em.$.ajax
      type: 'POST',
      url: "/api/v0/hosts/#{App.container.host_id}/start",
      headers: { Authorization: "Bearer #{App.get 'token'}" }

  startContainer: ->
    Em.RSVP.Promise.cast Em.$.ajax
      type: 'POST',
      url: "/api/v0/containers/#{App.container.slug}/start",
      headers: { Authorization: "Bearer #{App.get 'token'}" }

  resumeSessionErrDialog: (msg)->
    App.ResumeSessionDialog.create
      message: msg

  hostStoppedErrDialog: ->
    App.ErrorDialog.create
      errorMessage: hostStoppedMessage
      redirectUrl: "/app/#/workspaces/#{App.container.host.slug}"
      okButtonText: 'Back to Dashboard'

  containerStoppedErrDialog: ->
    App.ErrorDialog.create
      errorMessage: containerStoppedMessage
      redirectUrl: "/app/#/containers/#{App.container.slug}"
      okButtonText: 'Back to Dashboard'

  opsSocketDisconnected: (->
    unless @get('opsSocketReady')
      opsTimeoutAlert = Em.run.later this, (->
        @set 'opsConnectionLost', true
      ), @get('opsConnectionGracePeriod')

      @set 'opsTimeoutAlert', opsTimeoutAlert
  ).observes 'opsSocketReady'

  opsSocketConnected: (->
    if @get('opsSocketReady') && (opsTimeoutAlert = @get('opsTimeoutAlert'))
      Em.run.cancel opsTimeoutAlert
      @set 'opsConnectionLost', false

      if repo = @get 'repository'
        if repo.get('state') == 'failed'
          cacheKey = "repo:#{repo.get('id')}:shownError"
          if !App.localStorage.get(cacheKey)
            App.set 'flashMessage', { type: 'error', text: "Failed to clone repository: #{repo.get('failure_reason')}" }
            App.localStorage.set(cacheKey, true)
  ).observes 'opsSocketReady'

  collabSocketDidStartForTheFirstTime: (->
    if @get 'collabSocket.startedFirstTime'
      fileMon = App.ActiveFilesMonitor.create(collabSocket: @get('collabSocket'), username: App.get('user.username'))
      @set 'activeFilesMonitor', fileMon
  ).observes 'collabSocket.startedFirstTime'

  opsSocketDidStartForTheFirstTime: (->
    if @get 'opsSocket.startedFirstTime'
      socket = @get 'opsSocket'
      App.CodePluginsManager.setAvailableOption 'opsSocket', socket
  ).observes 'opsSocket.startedFirstTime'

  warnWhenOffline: (->
    if App.get 'offline'
      App.set 'flashMessage', { type: 'alert-error', text: "Unable to connect to the server. Changes will not be saved.", sticky: true }
    else
      App.set 'flashMessage', null
  ).observes 'App.offline'

  loadFreighterFeatures: (container)->
    @getFreighterFeatures(container).then =>
      if @loadFreighterFeaturesRetry
        window.clearTimeout @loadFreighterFeaturesRetry
      features = App.get('freighterdFeatures') ? []

      if features.contains('collab')
        @set 'collabEnabled', true
        @set 'collabSocket', collabSocket = App.CollabSocket.create(container: container)
        collabSocket.connect()
    , (jqxhr) =>
      return if @loadFreighterFeaturesRetry
      @loadFreighterFeaturesRetry = window.setTimeout(=>
        @loadFreighterFeaturesRetry = null
        @loadFreighterFeatures(container)
      , freighterFeaturesRetry)

  getFreighterFeatures: (container) ->
    protocol = location.protocol
    freighterdUrl = container.get 'freighterdUrl'
    url = "#{protocol}//#{freighterdUrl}/features"

    Em.RSVP.Promise.cast(Em.$.ajax(
      type: 'GET'
      url: url
      dataType: 'json'
    )).then (data) ->
      if Em.isArray(data.features)
        App.set 'freighterdFeatures', data.features
