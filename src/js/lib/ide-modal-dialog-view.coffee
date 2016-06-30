App.IdeModalDialogView = Em.View.extend
  classNames: ['ui', 'modal']

  showOrHide: (->
    if @get 'content.hide'
      @hide()
    else if @get 'content'
      @show()
  ).observes 'content', 'content.hide'

  show: ->
    ui.showModal @$(), =>
      @viewDidAppear()

  hide: ->
    ui.hideModal @$(), =>
      @viewDidDisappear()

  viewDidAppear: ->

  viewDidDisappear: ->
    @set 'content', null

  actions:
    didClickCancel: ->
      @hide()
