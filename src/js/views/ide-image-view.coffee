App.IdeImageView = Em.View.extend
  templateName: 'image'
  classNames: ['ide-image-view']
  classNameBindings: ['document.active', 'zoomed']

  document: null

  zoomed: false

  uri: (->
    if (imageData = @get 'document.content') && (contentType = @get 'document.contentType')
      "data:#{contentType};base64,#{imageData}"
    else
      @get 'document.content'
  ).property 'document.content', 'document.contentType'

  bgImage: (->
    "background: url(#{@get 'uri'}) top left no-repeat; background-size: contain;"
  ).property 'uri'

  closeImage: (->
    if @get 'document.path.deleted'
      this.remove()
  ).observes 'document.path.deleted'

  click: ->
    @toggleProperty 'zoomed'
