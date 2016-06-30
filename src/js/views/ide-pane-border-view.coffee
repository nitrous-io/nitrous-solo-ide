App.IdePaneBorderView = Em.View.extend
  classNames: ['ide-pane-border-view']

  paneSelector: null

  mouseDidMove: (event) ->
    # implement me

  mouseDown: (event) ->
    event.preventDefault()

    $body = $('body')

    id = @get 'elementId'

    $body.on "mousemove.#{id}", (event) =>
      @mouseDidMove(event)

    $body.on "mouseup.#{id}", (event) =>
      @turnOffResizeEvents()

    $(window).on "mouseup.#{id}", (event) =>
      @turnOffResizeEvents()

    # place a transparent layer on top of iframes
    # to prevent iframe from blocking mouse events
    $('iframe').each ->
      $iframe = $(this)
      $iframeCover = $('<div class="iframe-cover" style="position: absolute; width: 100%; height: 100%; top: 0; left: 0; background: transparent">')
      $iframeCover.insertAfter($iframe)

  turnOffResizeEvents: ->
    id = @get 'elementId'
    $body = $('body')
    $body.off "mousemove.#{id}"
    $body.off "mouseup.#{id}"
    $(window).off "mouseup.#{id}"
    $('.iframe-cover').remove()

  willDestroyElement: ->
    @_super()
    @turnOffResizeEvents()
