App.IdeView = Em.View.extend
  templateName: 'ide/ide'
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
    #Mp.track Mp.EventIDEStarted, container_id: @get 'controller.id'
    #Mp.increment Mp.PropertyIDEStartCount

  willDestroyElement: ->
    @_super()
    #Mp.track Mp.EventIDEDeparted, container_id: @get 'controller.id'
    #if started = @get('timeStarted')
      #Mp.increment Mp.PropertyIDEUseTime, Date.now() - started
    $('html').removeClass 'ide'
    $(window).unbind 'keydown.ideView'
