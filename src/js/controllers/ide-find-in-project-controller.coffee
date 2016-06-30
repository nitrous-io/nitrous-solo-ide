App.IdeFindInProjectController = Em.Controller.extend
  needs: ['ide', 'ideEditor']

  opsSocketBinding: Em.Binding.oneWay 'controllers.ide.opsSocket'
  findInProjectDialog: null
  termBinding: Ember.Binding.oneWay('findInProjectDialog.term')
  locationBinding: Ember.Binding.oneWay('findInProjectDialog.location')
  caseSensitiveBinding: Ember.Binding.oneWay('findInProjectDialog.caseSensitive')
  useRegexpBinding: Ember.Binding.oneWay('findInProjectDialog.useRegexp')
  filePatternBinding: Ember.Binding.oneWay('findInProjectDialog.filePattern')

  invalidField: null

  reset: ->
    @set 'findInProjectDialog.hide', true
    @set 'findInProjectDialog', null

  valid: ->
    @set 'invalidField', null
    if (@get('term') || '').trim() == ''
      @set 'invalidField', 'term'
      return false
    true

  showFindDialog: (location) ->
    @set 'findInProjectDialog', App.FindInProjectDialog.create location: location

  actions:
    find: ->
      if !@valid()
        App.postError "Invalid #{@get 'invalidField'}"
        return

      term = @get('term')
      location = @guessPath(@get('location'))
      ignoreCase = !@get('caseSensitive')
      useRegexp = @get('useRegexp')
      filePattern = @get('filePattern')

      socket = @get('opsSocket')
      editorController = @get('controllers.ideEditor')
      tab = editorController.createTab({ term: term, path: location, multiple: true }, App.SearchResults)

      # Generate a unique search ID so that we can handle concurrent searches.
      searchId = Date.now().toString()

      onOutput = (err, data) ->
        return unless data?.request?.id == searchId
        if err
          removeHandlers()
          return
        if data.results?.length
          tab.addSearchResults(data.results)

      onError = (err, data) ->
        return unless data?.request?.id == searchId
        removeHandlers()
        tab.addError(err || data.error)

      onCompleted = (err, data) ->
        return unless data?.request?.id == searchId
        removeHandlers()
        tab.doComplete()

      removeHandlers = ->
        socket.off 'search.output', onOutput
        socket.off 'search.error', onError
        socket.off 'search.completed', onCompleted

      socket.on 'search.output', onOutput
      socket.on 'search.error', onError
      socket.on 'search.completed', onCompleted

      socket.search searchId, term, location, ignoreCase, useRegexp, filePattern, (err) =>
        if err
          App.postError err
          return
        this.reset()

  guessPath: (path) ->
    homeDir = App.get('container.homePath')
    return homeDir if not path?.length || path == homeDir

    # Leave paths within home dir unchanged.
    return path if path.match(new RegExp("^#{homeDir}\/"))

    [homeDir, path].join('/')
