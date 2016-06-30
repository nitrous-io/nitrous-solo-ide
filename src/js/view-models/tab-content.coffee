# parent class for all view-models that can be displayed in a tab
App.TabContent = Em.Object.extend
  active: false
  focused: false
  clean: true

  content: ''
  path: null
  contentType: null

  tooltip: (->
    @get('path.absolutePath') || @get('title')
  ).property 'path.absolutePath'
