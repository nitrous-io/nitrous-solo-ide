App.Menu = Em.Object.extend
  name: null
  items: null

  init: ->
    @set 'items', [] unless @get 'items'
    @_super.apply this, arguments

