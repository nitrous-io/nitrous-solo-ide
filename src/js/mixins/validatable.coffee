App.Validatable = Em.Mixin.create
  firstErrors: (->
    o = {}
    if errors = @get 'errors'
      Em.keys(errors).forEach (key) ->
        o[key] = errors[key][0]
    o
  ).property 'errors'

  validations: {}

  validate: ->
    errors = null

    _.each @get('validations'), (fns, key) =>
      fns = [fns] unless _.isArray(fns)
      value = @get(key)
      _.each fns, (fn) ->
        if msg = fn(value)
          errors ||= {}
          errors[key] ||= []
          errors[key].push(msg)

    @set 'errors', errors
    errors

