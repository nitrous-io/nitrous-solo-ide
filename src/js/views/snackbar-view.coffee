snackbarHeight = 48
snackbarMarginTop = 16

App.SnackbarView = Em.View.extend
  tagName: 'ul'
  templateName: 'snackbar'
  classNames: ['snackbar-view', 'ui', 'snackbar']

  items: null

  updateHeight: (->
    @$().css(height: (snackbarHeight + snackbarMarginTop) * @get('items.length'))
  ).observes 'items.length'

  actions:
    didClick: (item) ->
      App.get('snackbar').fadeOutItem(item, 100)
