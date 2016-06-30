#= require ./ide-pane-border-view

App.IdeSidebarBorderView = App.IdePaneBorderView.extend
  elementId: 'ide-sidebar-border-view'

  minWidth: 250
  width: 250

  mouseDidMove: (event) ->
    $pane = $('#ide-sidebar-view')
    minWidth = @get 'minWidth'
    newWidth = Math.floor(Math.max(event.pageX - $pane.offset().left, minWidth))
    $pane.css(width: "#{newWidth}px")
    @set 'width', newWidth
