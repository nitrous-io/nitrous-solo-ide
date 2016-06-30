#= require ./tab-content

App.Image = App.TabContent.extend
  isImageTab: true

  title: (->
    @get('path.name')
  ).property 'path.name'
