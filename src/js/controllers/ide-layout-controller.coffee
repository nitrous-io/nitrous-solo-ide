App.IdeLayoutController = Em.Controller.extend
  collaborationPaneHidden: false

  initialize: ->
    @set 'collaborationPaneHidden', (App.localStorage.get('collaborationPaneHidden') ? false)

  reset: ->

  _collaborationPaneHiddenDidChange: (->
    App.localStorage.set 'collaborationPaneHidden', @get('collaborationPaneHidden')
  ).observes 'collaborationPaneHidden'
