App.SelectableTextField = Em.TextField.extend
  attributeBindings: ['readonly']

  init: ->
    @set 'readonly', 'readonly'
    @_super.apply this, arguments

  click: ->
    @$().select()

