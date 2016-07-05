require './tab-content'

LINE_ERROR_MATCH = /\.go:(\d+):(\d+):?\s+(.+)$/

untitledCount = 0

App.Document = App.TabContent.extend
  isDocumentTab: true
  contentType: 'text'

  otClient: null
  otUndoManagerOverride: null

  findTrigger: null
  findNextTrigger: null
  findPrevTrigger: null
  findError: null

  replaceTrigger: null
  replaceAllTrigger: null
  selectNextTrigger: null

  documentLastUpdated: null

  foldCodeTrigger: null
  unfoldCodeTrigger: null
  toggleCommentTrigger: null
  splitSelectionIntoLinesTrigger: null
  removeTrailingWhitespaceTrigger: null

  goToLine: null
  selections: null
  scrollPosition: null

  errorCountBinding: 'lineWidgets.length'

  readOnly: false

  lineWidgets: Em.A([])

  line: (->
    (@get('selections.0.head.line') || 0) + 1
  ).property 'selections'

  column: (->
    (@get('selections.0.head.ch') || 0) + 1
  ).property 'selections'

  title: (->
    @get('path.name') || "Untitled #{untitledCount += 1}"
  ).property 'path.name'

  observeReplaceContentTrigger: (->
    return unless @get('replaceContentTrigger')
    @set 'documentLastUpdated', Date.now()
  ).property 'replaceContentTrigger'

  isOTMaster: ->
    cl = @get 'otClient'
    return true unless cl
    clientIDs = Object.keys(cl.clients)
    return true if clientIDs.length == 0
    myID = App.get 'router.ideController.collabSocket.connID'
    smallestID = clientIDs.reduce (a,b)->
      a < b ? a : b
    myID < smallestID

  processErrMessage: (stderr)->
    errors = Em.A([])
    if stderr
      messages = stderr.trim().split('\n')
      for line in messages
        match = line.match(LINE_ERROR_MATCH)
        if match
          msg = document.createElement('div')
          excl = document.createElement('i')
          excl.className = "fa fa-exclamation-circle"
          msg.appendChild(excl)
          msg.appendChild(document.createTextNode(" " + match[3]))
          msg.className = 'line-error-message'
          errors.push({line: parseInt(match[1])-1, node: msg, options: {coverGutter: false}})
    @set 'lineWidgets', errors
