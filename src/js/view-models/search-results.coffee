#= require ./tab-content

App.SearchResults = App.TabContent.extend
  isSearchTab: true

  content: ''
  path: null
  contentType: 'search-results'

  term: null
  results: null
  errors: null
  fileCount: 0
  matchCount: 0
  completed: false

  init: ->
    @_super()
    @set 'results', Ember.A([])
    @set 'errors', Ember.A([])

  doComplete: ->
    @set 'completed', true

  title: (->
    if term = @get('term')
      termTitle = if term.length > 6 then term.slice(0, 6) + "..." else term
      "Search results: '#{termTitle}'"
    else
      "Searching..."
  ).property 'term'

  tooltip: (->
    "Search results: '#{@get('term')}'"
  ).property 'term'

  status: (->
    termText = "'#{@get('term')}'"
    if @get('matchCount') == 0 && @get('fileCount') == 0
      if @get('completed')
        "No results found searching for #{termText} in #{@get('path')}"
      else
        'Searching...'
    else
      parts = [
        App.util.pluralize @get('matchCount'), 'match', 'matches'
        'in'
        App.util.pluralize @get('fileCount'), 'file', 'files'
        "searching for #{termText} in #{@get('path')}"
      ]
      if @get('completed')
        parts.unshift('Completed:')
      parts.join(' ')
  ).property 'fileCount', 'matchCount', 'completed', 'term'

  addSearchResults: (newResults) ->
    _.each newResults, (res) =>
      # file: "test.rb", matches: [content: "import foofoo", row: 1, count: 2]
      return if !res.matches || res.matches.length == 0

      result = Em.Object.create
        filename: [@get('path'), res.file].join('/')
        matchCount: res.matches.length
        lines: []

      _.each res.matches, (match) =>
        line = Em.Object.create
          lineNumber: match.row
          text: match.highlighted_content
        result.get('lines').pushObject(line)
        @incrementProperty 'matchCount', match.count

      @get('results').pushObject(result)
      @incrementProperty 'fileCount'

  addError: (error) ->
    if errorMsg = @friendlyError(error)
      @get('errors').pushObject(errorMsg)

  friendlyError: (error) ->
    switch
      when error.match /has more than \d+ results/
        "Search returned too many results. Some results have been omitted. Please try a more specific search."
      else
        # Don't display error messages in their raw form because there're not
        # helpful to end users.
        null
