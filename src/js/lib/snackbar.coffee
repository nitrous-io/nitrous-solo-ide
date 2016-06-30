App.Snackbar = Em.Object.extend
  items: null

  init: ->
    @set 'items', Em.A()

  post: (msg, options = {}) ->
    p =
      duration: 5500
      sticky: false
    Object.assign(p, options)
    return if msg == @get('items.firstObject.message')
    items = @get('items')
    item = items.unshiftObject(App.SnackbarItem.create(message: msg.toString(), sticky: p.sticky))

    # fade in
    window.setTimeout(->
      item.set 'fadein', true
    , 100)
    # fade out
    unless p.sticky
      window.setTimeout(=>
        @fadeOutItem(item)
      , p.duration)

    item

  fadeOutItem: (item) ->
    return if item.get 'closing'
    item.set 'closing', true
    item.set 'fadeout', true
    # remove item from parent
    window.setTimeout(=>
      @get('items').removeObject(item)
    , 1000)

App.SnackbarItem = Em.Object.extend
  message: null
  fadein: false
  fadeout: false
  sticky: false
  closing: false
