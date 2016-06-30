App.FileFinderDialog = klass = Em.Object.extend
  pattern: null
  basePath: null
  results: null

  selectedIndex: null
  currentSearch: null

  error: null

  init: ->
    @_super()
    # results caches the matched results for a (term, path)
    # possible values enumerated in searchStatus
    @set 'results', Em.Object.create()
    @set 'selectedIndex', 0

  # calls cb if the pattern cannot be found locally
  find: (pattern, path, cb) ->
    found = this.hasResults(pattern, path) or this.filterResults(pattern, path)
    if !found && this.searchStatus(pattern, path) == 'unknown'
      cb()

  # if remaining results are less than maxResults, we filter client-side
  filterResults: (pattern, path) ->
    results = @get('currentResults')
    return if !results
    canFilter = pattern && pattern.length > 1 && this.hasResults(pattern.slice(0, -1), path) &&
      results.length < klass.maxResults
    return if !canFilter

    results = @get this.resultsKey(pattern.slice(0, -1), path)
    re = new RegExp(pattern.replace(/./g, (char) -> ".*?#{char}") + ".*?", 'i')
    results = _.filter results, (item) ->
      item.filename.match(re)
    @set this.resultsKey(pattern, path), results
    this.searchComplete(pattern, path)
    true

  searchStatus: (pattern, path) ->
    results = @get this.resultsKey(pattern, path)
    switch
      when @get('error')
        'error'
      when results == undefined
        'unknown'
      when results == null
        'zero' # search completed with no results
      when results instanceof Array && results.length == 0
        'started'
      when results instanceof Array && results.length > 0
        'results'
      else
        'error'

  currentStatus: (->
    this.searchStatus(@get('currentSearch'), @get('basePath'))
  ).property 'currentResults', 'error'

  showStatus: (->
    return false if @get('currentSearch')?.length == 0
    !_.contains(['unknown', 'results'], @get('currentStatus'))
  ).property 'currentStatus'

  searchStart: (pattern, path) ->
    key = this.resultsKey(pattern, path)
    if @get(key) == undefined
      @set key, Ember.A([])
      @set 'newResults', Date.now()

  searchComplete: (pattern, path) ->
    return if this.hasResults(pattern, path)
    @set this.resultsKey(pattern, path), null
    @set 'newResults', Date.now()

  hasResults: (pattern, path) ->
    this.searchStatus(pattern, path) == 'results'

  humanStatus: (->
    switch @get 'currentStatus'
      when 'error'
        if error = @get('error') then error else 'Error finding'
      when 'zero'
        'No results found'
      when 'started'
        'Searching...'
      else
        null
  ).property 'currentStatus'

  placeholder: (->
    "Fuzzy find files in #{@get 'prettyPath'}"
  ).property 'prettyPath'

  prettyPath: (->
    path = @get 'basePath'
    if path == '.'
      'all directories'
    else
      if path.slice(-1) == '/' then path else path + '/'
  ).property 'basePath'

  currentResults: (->
    @get(@get('currentKey'))
    # cannot observe 'results' directly for new keys, so whenever results are
    # updated, newResults property needs to be touched
  ).property 'newResults', 'currentKey'

  currentKey: (->
    this.resultsKey @get('currentSearch'), @get('basePath')
  ).property 'currentSearch', 'basePath'

  addResults: (pattern, path, newResults) ->
    results = @get this.resultsKey(pattern, path)
    _.each newResults, (result) =>
      filename = result.substr(result.lastIndexOf('/')+1)
      results.pushObject Em.Object.create(filename: filename, path: result, absolutePath: [path, result].join('/') )
    @set 'newResults', Date.now()

  incrementIndex: ->
    index = @get 'selectedIndex'
    results = (@get 'currentResults') || []
    @incrementProperty('selectedIndex') if index + 1 < results.length

  decrementIndex: ->
    index = @get 'selectedIndex'
    results = (@get 'currentResults') || []
    @decrementProperty('selectedIndex') if index - 1 >= 0

  selectedFile: (->
    results = @get 'currentResults'
    return if !results
    results.objectAt(@get 'selectedIndex')
  ).property 'currentResults.@each.filename', 'selectedIndex'

  updateSelected: (->
    results = @get 'currentResults'
    return if !results
    selectedIndex = @get 'selectedIndex'
    results.forEach (result, index) ->
      result.set 'selected', index == selectedIndex
  ).observes 'currentResults.@each.filename', 'selectedIndex'

  resetSelected: (->
    @set 'selectedIndex', 0
  ).observes 'newResults'

  resultsKey: (pattern, path) ->
    "results.#{klass.keyFor(pattern, path)}"

klass.reopenClass
  maxResults: 10

  # separator between file pattern and path so that (pattern1, path1) and
  # (pattern2, path2) do not overlap
  searchKeyDelimiter: "\\\\"

  keyFor: (pattern, path) ->
    # pattern cannot have dots as it will cause issues when setting
    # "results.#{key}"
    [pattern, path].join(this.searchKeyDelimiter).replace(/\./g, "~")
