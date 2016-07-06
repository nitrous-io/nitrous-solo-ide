App.IdeView = Em.View.extend
  templateName: 'ide'
  elementId: 'ide-view'

  timeStarted: null

  willInsertElement: ->
    @_super()
    $('html').addClass 'ide'

    # prevent accidental backspacing
    $(window).bind 'keydown.ideView', (e) ->
      if e.keyCode == 8 && $(e.target).is('body')
        e.preventDefault()

  didInsertElement: ->
    @_super()
    Em.run.scheduleOnce 'afterRender', ->
      webapp?.loading.stop()
    controller = @get 'controller'
    controller.validateHostAndContainerState()
    @set('timeStarted', Date.now())

  willDestroyElement: ->
    @_super()
    $('html').removeClass 'ide'
    $(window).unbind 'keydown.ideView'
