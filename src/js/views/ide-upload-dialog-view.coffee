App.IdeUploadDialogView = App.IdeModalDialogView.extend
  templateName: 'upload-dialog'
  elementId: 'ide-upload-dialog-view'
  contentBinding: 'controller.uploadDialog' # controler = ideSidebarController
  classNameBindings: ['content.uploading:uploading']

  dragAndDropCapable: (->
    div = document.createElement('div')
    div.draggable? || (div.ondragstart != undefined && div.ondrop != undefined)
  ).property()

  uploadURI: (->
    if container = App.get('container')
      freighterdUrl = container.get 'freighterdUrl'
      cid = container.get 'cid'
      "https://#{freighterdUrl}/containers/#{cid}/upload"
  ).property 'App.container'

  didInsertElement: ->
    @_super()
    $files = @$ '.files'
    @$('.file-input').fileupload
      url: @get('uploadURI')
      formData: =>
        [
          { name: "token", value: @get('content.authToken') },
          { name: "location", value: @get('content.path.absolutePath') }
        ]
      dataType: 'json'
      maxFileSize: 20 * 1000 * 1000
      singleFileUploads: true
      sequentialUploads: true
      dropZone: @$('.drop-zone')
      add: _.bind(@didAddUpload, this)
      progress: _.bind(@progressDidChange, this)
      done: _.bind(@uploadDidSucceed, this)
      fail: _.bind(@uploadDidFail, this)

  didAddUpload: (event, data) ->
    content = @get 'content'
    fileName = data.files[0].name
    if content && !content.get('uploading') && !content.findProperty('fileName', fileName)
      content.addObject App.Upload.create(data: data)

  progressDidChange: (event, data) ->
    if content = @get 'content'
      fileName = data.files[0].name
      upload = content.findProperty 'fileName', fileName
      upload.set 'progressInterval', data.progressInterval

  uploadDidSucceed: (event, data) ->
    if content = @get 'content'
      fileName = data.files[0].name
      upload = content.findProperty 'fileName', fileName
      upload.set 'completed', true
      path = content.get 'path.absolutePath'
      filePath = if path.length > 0
        "#{path}/#{fileName}"
      else
        fileName
      @get('controller').didFinishAnUpload filePath

  uploadDidFail: (event, data) ->
    if content = @get 'content'
      fileName = data.files[0].name
      upload = content.findProperty 'fileName', fileName
      upload.set 'completed', true
      upload.set 'failed', true
      if data.errorThrown && data.errorThrown.indexOf("Too Large") != -1
        upload.set 'tooLarge', true
      @get('controller').didFinishAnUpload()

  actions:
    didClickRemoveUpload: (upload) ->
      if content = @get 'content'
        content.removeObject upload

    didClickUpload: ->
      @get('controller').beginUpload()

App.IdeUploadDialogDropZoneView = Em.View.extend
  classNames: ['drop-zone']
  classNameBindings: ['draggingOver:dragging-over']
  draggingOver: false

  dragOver: (event) ->
    @set 'draggingOver', true

  dragLeave: (event) ->
    @set 'draggingOver', false

  drop: (event) ->
    @set 'draggingOver', false
