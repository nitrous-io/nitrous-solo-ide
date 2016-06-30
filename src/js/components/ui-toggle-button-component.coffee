App.UiToggleButtonComponent = Em.Component.extend
  tagName: 'button'
  classNames: ['ui', 'btn', 'toggle-button']
  classNameBindings: ['on:on']
  attributeBindings: ['disabled', 'title']

  on: false

  click: ->
    @toggleProperty 'on'
    false
