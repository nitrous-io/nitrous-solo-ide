require './ide-pane-border-view'

App.IdeConsoleBorderView = App.IdePaneBorderView.extend
  elementId: 'ide-console-border-view'
  classNames: ['horizontal']

  minHeight: 165
  height: 165

  mouseDidMove: (event) ->
    $pane = $('#ide-console-view')
    minHeight = @get 'minHeight'
    newHeight = Math.floor(Math.max(($pane.offset().top + $pane.innerHeight()) - event.pageY, minHeight))
    $pane.css(height: "#{newHeight}px")
    @set 'height', newHeight
