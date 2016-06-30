App.IdeGitController = Em.Controller.extend
  needs: ['ideConsole']

  containerKeyAddedToGitHub: false
  cloneFromGitHubDialog: null
  selectedRepository: null
  githubRepos: null

  initialize: ->
    @updateContainerKeyStatus()

  reset: ->
    @updateContainerKeyStatus()
    if @get 'cloneFromGitHubDialog'
      @set 'cloneFromGitHubDialog.hide', true
      @set 'cloneFromGitHubDialog', null

  showCloneFromGitHubDialog: ->
    cloneFromGitHubDialog = App.CloneFromGitHubDialog.create()
    if @get('githubRepos')
      @set 'cloneFromGitHubDialog', cloneFromGitHubDialog
      cloneFromGitHubDialog.set('loaded', true)
      cloneFromGitHubDialog.set('repositories', @get('githubRepos'))
    else
      if @get('containerKeyAddedToGitHub')
        @set 'cloneFromGitHubDialog', cloneFromGitHubDialog
        Em.$.ajax(
          type: 'GET'
          url: '/api/v0/github/repos'
          headers: { Authorization: "Bearer #{App.get 'token'}" }
        ).done((data) =>
          cloneFromGitHubDialog.set('loaded', true)
          repos = cloneFromGitHubDialog.get('repositories')
          for repo in data.repos
            repos.pushObject(repo)
          @set 'githubRepos', repos
        ).fail (jqxhr) =>
          App.postError(jqxhr.responseJSON, 'Failed to get repos!')
      else
        cloneFromGitHubDialog.setProperties
          error: "Please add your container key to GitHub"
          loaded: true
        @set 'cloneFromGitHubDialog', cloneFromGitHubDialog

  openTerminalAndCloneRepo: (gitUrl) ->
    # i.e. git://github.com/username/project-name.git => project-name
    matches = gitUrl.match(/\/([^\/]+)\.git$/)
    if matches
      cloneDir = "/home/nitrous/code/#{matches[1]}"
      tab = App.ConsoleSession.create(initCommand: "git clone #{gitUrl} #{cloneDir} && cd #{cloneDir}")
      @get('controllers.ideConsole').addTab tab, {}
      #Mp.increment Mp.PropertyIDEGitCloneCount

  updateContainerKeyStatus: ->
    Em.$.ajax(
      type: 'GET'
      url: "/api/v0/containers/#{App.get('container').slug}/container_keys/status"
      headers: { Authorization: "Bearer #{App.get 'token'}" }
    ).done (data) =>
      @set 'containerKeyAddedToGitHub', data.added_to_github
