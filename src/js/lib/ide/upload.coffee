App.Upload = Em.Object.extend
  data: null
  progressInterval: 0
  completed: false
  failed: false
  tooLarge: false

  success: (->
    @get('completed') && !@get('failed')
  ).property 'failed', 'completed'

  file: (->
    if data = @get 'data'
      data.files[0]
  ).property 'data'

  fileName: (->
    if file = @get 'file'
      file.name
  ).property 'file'

  fileSize: (->
    if file = @get 'file'
      file.size
  ).property 'file'

  widthStyle: (->
    if @get 'failed'
      'width: 100%'
    else
      "width: #{@get 'progressInterval'}%"
  ).property 'progressInterval', 'failed'

  submit: ->
    @get('data')?.submit()

