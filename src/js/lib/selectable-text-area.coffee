App.SelectableTextArea = Em.TextArea.extend
  attributeBindings: ['readonly']

  init: ->
    @set 'readonly', 'readonly'
    @_super.apply this, arguments

  click: ->
    @$().select()

