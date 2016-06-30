require './events-socket'

App.EventMessageHandler = App.EventsSocket.extend
  init: ->
    @_super.apply this, arguments
    @_addEventHandlers()

  _addEventHandlers: ->
    ['container.created', 'container.destroyed', 'host.restarted'].forEach (evt) =>
      @on evt, (data) ->
        findAllContainers()?.reload()

    ['container.starting', 'container.stopping', 'container.stopped', 'container.restarting',
     'container.updated', 'container.reconfiguring', 'container.reconfigure_failed'].forEach (evt) =>
      @on evt, (data) ->
        containerData = data.container
        if container = findContainer(containerData)
          container.eventOccurred(evt)
          container.load(containerData)
          container.loadConfig()

    ['container.started', 'container.restarted', 'container.reconfigured'].forEach (evt) =>
      @on evt, (data) ->
        containerData = data.container
        if container = findContainer(containerData)
          container.eventOccurred(evt)
          container.load(containerData)
          # Reload container data so that we get a full set of data that is
          # missing from the event, such as the sshURL.
          container.reload()
          container.loadConfig()

    ['hosts.refreshed', 'host.created', 'host.create_failed', 'host.destroyed'].forEach (evt) =>
      @on evt, (data) ->
        findAllHosts()?.reload()

    @on 'host.creating', (data) =>
      return unless host = findHostBySlug(data)
      if progress = parseProgress(data)
        host.set 'progress', progress

    ['host.create_failed', 'host.created'].forEach (evt) =>
      @on evt, (data) =>
        hostData = data.host
        return unless host = findHostBySlug(hostData)
        host.load(hostData)
        host.set 'progress', null

    ['host.restarted', 'host.restarting', 'host.updated',
      'host.stopping', 'host.stopped', 'host.starting', 'host.started',
      'host.respeccing', 'host.respec_failed'].forEach (evt) =>
      @on evt, (data) ->
        hostData = data.host
        return unless host = findHost(hostData)
        host.load(hostData)

    ['host.respecced'].forEach (evt) =>
      @on evt, (data) ->
        hostData = data.host
        return unless host = findHost(hostData)
        host.load(hostData)
        # if a record is loaded directly from a _fetchMultiple it lacks a reload func
        # unless it has also been _fetchOne on. We use .fetch which will reuse the object
        if host.reload
          host.reload()
        else
          App.Host.fetch(host.get('slug'))
        host.fetchStats()

    ['volume.created', 'volume.destroyed'].forEach (evt) =>
      @on evt, (data) ->
        volumeData = data.volume
        findAllVolumes(volumeData)?.reload()

    ['registry.added', 'registry.removed'].forEach (evt) =>
      @on evt, (data) ->
        registryData = data.registry
        findAllRegistries(registryData)?.reload()

    ['image.created', 'image.removed', 'image.tagged'].forEach (evt) =>
      @on evt, (data) ->
        imageData = data.image
        findAllImages(imageData)?.reload()

    ['image.building', 'image.pulling'].forEach (evt) =>
      @on evt, (data) ->
        return unless image = findImage(data)
        if progress = parseProgress(data)
          image.set 'progress', progress

    ['collaborator.added', 'collaborator.removed'].forEach (evt) =>
      @on evt, (data) ->
        if container = findContainer(data.container)
          # Make sure container is not deleted on user's workspace before reloading collaborators or GET /containers/{slug}/collaborators will return 404.
          if isOwner(data) || !isCollaborator(data) 
            container.get("collaborators").reload()

        if !isOwner(data)
          if App.get('sharedContainers')
            App.get('sharedContainers').reload()
          else
            App.set('sharedContainers', App.SharedContainer.fetch().value)

        if evt == "collaborator.added" && !isOwner(data)
          if isCollaborator(data)
            App.snackbar.post("#{data.initiated_by.username} added you to “#{data.container.slug}“")
          else
            App.snackbar.post("#{data.initiated_by.username} added “#{data.collaborator.username}“ to “#{data.container.slug}“")

        if evt == "collaborator.removed" && !isInitiator(data)
          if !isOwner(data) && isCollaborator(data)
            App.snackbar.post("#{data.initiated_by.username} removed you from “#{data.container.slug}“")
          if isOwner(data)
            App.snackbar.post("#{data.collaborator.username} left “#{data.container.slug}“")

    @on 'image.build_failed', (data) ->
      findImage(data)?.set 'progress', null

    @on 'image.built', (data) ->
      imageData = data.image
      return unless image = findImage(imageData)
      image.load(imageData)
      image.set 'progress', null

    ['image.pulled', 'image.pull_failed'].forEach (evt) =>
      @on evt, (data) ->
        imageData = data.image
        return unless image = findImage(imageData)
        image.load(imageData)
        image.set 'updating', false
        image.set 'progress', null

    @on 'image.updated', (data) ->
      imageData = data.image
      findImage(imageData)?.load(imageData)

    @on 'image.pushed', (data) ->
      imageData = data.image
      return unless imageData && (image = findImage(imageData))
      image.load(imageData)
      image.set 'pushing', false

    @on 'invoice.updated', (data) ->
      App.refreshBillingProfile()
      if (data.invoice && inv = App.get('invoices').findBy('id', data.invoice.id))
        inv.load(data.invoice)
        inv.set('awaitingUpdate', false)
      else
        App.refreshInvoices()

    @on 'subscription.updated', (data) ->
      if (data.subscription && sub = App.get('subscriptions').findBy('slug', data.subscription.slug))
        sub.load(data.subscription)
      else
        App.refreshSubscriptions()

    @on 'subscription.deleted', (data) ->
      App.refreshSubscriptions()

findAllContainers = ->
  App.get('containers')

findAllSharedContainers = ->
  App.get('sharedContainers')

findContainer = (data) ->
  pk = App.Container.primaryKey
  c = findAllContainers()?.findBy(pk, data[pk])
  if c
    return c
  return findAllSharedContainers()?.findBy(pk, data[pk])

findAllHosts = ->
  App.get('hosts')

findHost = (data) ->
  pk = App.Host.primaryKey
  findAllHosts()?.findBy(pk, data[pk])

findHostBySlug = (data) ->
  App.Host._findInCache(data.slug)

findHostByHostId = (data) ->
  findAllHosts()?.findBy('id', data.host_id)

findAllImages = (data) ->
  findHostByHostId(data)?.get('images')

findImage = (data) ->
  pk = App.Image.primaryKey
  App.Image._findInCache(data[pk])

findAllVolumes = (data) ->
  findHostByHostId(data)?.get('volumes')

findAllRegistries = (data) ->
  findHostByHostId(data)?.get('registries')

parseProgress = (data) ->
  return unless progress = data.progress
  progress = JSON.parse(progress)
  App.trigger("progressReceived", progress)
  if progress.status
    progress.status += "..."
  if progress.stream
    progress.status = progress.stream
  if bar = progress.progress
    eta = bar.match(/^\[.*\]\s+(.*)$/)?[1]
    id = progress.id
    if eta && id
      progress.status = "Downloading #{id}... #{eta}"
  progress

isCollaborator = (data) ->
  # collaborator data may not be passed in for pending invites, so you need to check if the values exist
  if data.collaborator && data.collaborator.id
      App.get('user.id') == data.collaborator.id

isOwner = (data) ->
  App.get('user.id') == data.container.user_id

isInitiator = (data) -> 
  App.get('user.id') == data.initiated_by.id
