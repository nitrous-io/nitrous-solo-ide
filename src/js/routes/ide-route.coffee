message = 'You will lose unsaved work if you close the IDE.'

App.IdeRoute = Em.Route.extend
  beforeModel: ->
    userFetch = App.User.fetch().then (user) ->
      App.set 'user', user
    userSettingsFetch = App.UserSettings.fetch().then (settings) ->
      App.set 'userSettings', settings
    Em.RSVP.allSettled([userFetch, userSettingsFetch])

  model: (params) ->
    @_super.apply this, arguments
    slug = params.containerSlug

    if !slug
      window.location.href = '/404.html'
    else
      App.loadContainer(slug).catch ->
        window.location.href = '/404.html'

  afterModel: (container, transition) ->
    container?.loadCollaborators()
    container?.loadHost().catch ->
      transition.abort()

  #renderTemplate: ->
    #@_super()
    #@render 'feedback', into: 'ide', outlet: 'feedback', controller: 'feedback'

  persistData: ->
    TabWatcher.syncChanges()
    App.get('userSettings')?.save()

  activate: ->
    # warn the user before actually unload the window. This is helpful to
    # prevent mis-click close tab / cmd + w
    return if App.get 'redirecting'
    $(window).bind 'beforeunload.ide', (ev)=>
      @persistData()
      message

  deactivate: ->
    $(window).unbind 'beforeunload.ide'

  setupController: (controller) ->
    @_super.apply this, arguments
    controller.initialize()

  actions:
    willTransition: (transition) =>
      @persistData()
      return true if App.get 'isChromeWebView'
      return true if App.get 'redirecting'
      return true if window.confirm(message + '\n\nAre you sure you want to leave this page?')
      url = transition.router.recognizer.generate 'box.ide', box_id: this.get('controller.content.id')
      transition.router.updateURL(url)
      transition.abort()
