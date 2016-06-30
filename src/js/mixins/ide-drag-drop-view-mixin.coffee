App.IdeDragDropViewMixin = Em.Mixin.create
  draggable: 'true'

  dragStart: (event) ->
    event.stopPropagation()
    dataTransfer = event.originalEvent.dataTransfer
    dataTransfer.setData "text/plain", '' # drag and drop in Firefox won't work if data is not set
    dataTransfer.effectAllowed = 'move'

  dragOver: (event) ->
    this._preventDefaultAndPropagation event

  dragEnter: (event) ->
    this._preventDefaultAndPropagation event

  dragLeave: (event) ->
    this._preventDefaultAndPropagation event

  drop: (event) ->
    this._preventDefaultAndPropagation event

  dragEnd: (event) ->
    this._preventDefaultAndPropagation event

  _preventDefaultAndPropagation: (event) ->
    event.preventDefault()
    event.stopPropagation()
