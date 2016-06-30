App.CloneFromGitHubDialog = klass = Em.Object.extend
  repositories: null
  loaded: false
  error: null

  init: ->
    @_super()
    @set('repositories', Em.A([]))
    @set('loaded', false)
    @set('error', null)

