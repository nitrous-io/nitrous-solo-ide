App.UploadDialog = Em.ArrayProxy.extend Em.SortableMixin,
  path: null
  content: null # array of App.Upload
  uploading: false
  authToken: null
  sortProperties: ['fileName']

  completed: (->
    if content = @get 'content'
      content.everyProperty 'success'
  ).property 'content.@each.success'

  init: ->
    @set 'content', Em.A()
    @_super.apply this, arguments
