App.SaveDialog = Em.Object.extend App.Validatable,
  path: ''
  saving: false
  document: null
  hide: false

  validations:
    path: (v) ->
      v = $.trim(v) if v
      if !v || v.substr(-1) == '/'
        'is not a valid path'
      else
        for pathComponent in v.split '/'
          unless pathComponent.match /^[^\/\\:\*\?"<>\|]*[^\/\\:\*\?"<>\|\.]+[^\/\\:\*\?"<>\|]*$/
            return 'is not a valid path'

