App.Editor = klass = Em.Object.extend
  domTarget: null
  codeMirror: null

  text: null

  readOnly: false

  autoCloseBrackets: null
  highlightLine: null
  keybindings: null
  matchBrackets: null
  mode: null
  rulerColumn: null
  showLineNumbers: null
  showTrailingSpace: null
  softTabs: null
  tabSize: null
  theme: null
  wrapLines: null
  wrapperStyling: null
  fontSize: null

  foldGutterClass: 'CodeMirror-foldgutter'

  macExtraKeys:
    'Tab': 'smartTab'
    'Ctrl-Space': 'autocomplete'
    'Cmd-/': 'toggleComment'
    'Cmd-Enter': 'insertLineAfter'
    'Shift-Cmd-Enter': 'insertLineBefore'
    'Ctrl-M': 'goMatchingBracket'
    'Cmd-D': 'selectNext'
    'Shift-Ctrl-D': 'duplicateLine'
    'Shift-Ctrl-K': 'deleteLine'
    'Cmd-Ctrl-Up': 'swapLineUp'
    'Cmd-Ctrl-Down': 'swapLineDown'
    'Cmd-Left': 'goLineLeftSmart'

  pcExtraKeys:
    'Tab': 'smartTab'
    'Ctrl-Space': 'autocomplete'
    'Ctrl-/': 'toggleComment'
    'Ctrl-Enter': 'insertLineAfter'
    'Shift-Ctrl-Enter': 'insertLineBefore'
    'Ctrl-M': 'goMatchingBracket'
    'Ctrl-D': 'selectNext'
    'Shift-Ctrl-D': 'duplicateLine'
    'Shift-Ctrl-K': 'deleteLine'
    'Shift-Ctrl-Up': 'swapLineUp'
    'Shift-Ctrl-Down': 'swapLineDown'
    'Alt-Left': 'goLineLeftSmart'

  # keybindings in codemirror default keymap that we use in menu
  macOverrideKeys: ['Cmd-D', 'Cmd-F', 'Cmd-Alt-F', 'Shift-Cmd-Alt-F', 'Cmd-G', 'Shift-Cmd-G']
  pcOverrideKeys: ['Shift-Ctrl-F', 'Ctrl-D', 'Ctrl-F', 'Shift-Ctrl-F', 'Shift-Ctrl-R', 'Ctrl+G']

  lintableMode: (->
    _.any CodeMirror.MODES_WITH_LINTING, (m) =>
      m == @get('mode')
  ).property 'mode'

  init: ->
    @_bootstrapCodeMirror()
    @_super.apply this, arguments

  destroy: ->
    if cm = @get('codeMirror')
      cm.off 'change'
      cm.off 'focus'
      cm.off 'blur'
      cm.off 'gutterClick'
      cm.off 'cursorActivity'
      cm.off 'scroll'

  on: ->
    if cm = @get 'codeMirror'
      cm.on.apply cm, arguments

  duplicateLine: ->
    if cm = @get('codeMirror')
      cm.execCommand('duplicateLine')

  deleteLine: ->
    if cm = @get('codeMirror')
      cm.execCommand('deleteLine')

  isClean: ->
    if cm = @get('codeMirror')
      cm.isClean()

  markClean: ->
    if cm = @get('codeMirror')
      cm.markClean()

  refresh: ->
    if cm = @get('codeMirror')
      cm.refresh()

  hasFocus: ->
    if cm = @get('codeMirror')
      cm.hasFocus()

  focus: ->
    window.focusedEditor = this
    if cm = @get('codeMirror')
      cm.focus() unless @hasFocus()

  blur: ->
    if cm = @get('codeMirror')
      cm.getInputField().blur()

  selectNext: ->
    if cm = @get 'codeMirror'
      cm.execCommand('selectNextOccurrence')
      cm.focus() unless @hasFocus()

  find: (query, reverse, matchCase, useRegex) ->
    if cm = @get 'codeMirror'
      return cm.find(query, reverse, matchCase, useRegex)

  replace: (query, text, all, matchCase, useRegex) ->
    if cm = @get 'codeMirror'
      cm.replace(query, text, all, matchCase, useRegex)

  clearSearch: ->
    if cm = @get 'codeMirror'
      cm.clearSearch()

  findNext: ->
    if cm = @get 'codeMirror'
      cm.findNext()

  findPrev: ->
    if cm = @get 'codeMirror'
      cm.findPrevious()

  fold: ->
    if cm = @get 'codeMirror'
      cm.execCommand('fold')

  unfold: ->
    if cm = @get 'codeMirror'
      cm.execCommand('unfold')

  goToLine: (line, cursor = 0) ->
    if cm = @get 'codeMirror'
      cm.setCursor(parseInt(line) - 1, cursor, scroll: true)
      cm.scrollIntoView() # above {scroll: true} option does not work as advertised

  setSelections: (selections) ->
    if cm = @get 'codeMirror'
      cm.setSelections(selections, 0, scroll: true)

  scrollTo: (opts) ->
    if cm = @get 'codeMirror'
      cm.scrollTo(opts.left, opts.top)

  toggleComment: ->
    if cm = @get 'codeMirror'
      cm.execCommand('toggleComment')

  splitSelectionIntoLines: ->
    if cm = @get 'codeMirror'
      cm.execCommand('splitSelectionByLine')

  removeTrailingWhitespace: ->
    if cm = @get 'codeMirror'
      cm.operation ->
        l = 0
        cm.eachLine (line) ->
          i = line.text.search /\s+$/
          if i != -1
            cm.replaceRange '', { line: l, ch: i }, { line: l, ch: line.text.length }
          l++
          false # needed to continue looping

  swapLineDown: ->
    if cm = @get('codeMirror')
      cm.swapLineDown()

  swapLineUp: ->
    if cm = @get('codeMirror')
      cm.swapLineUp()

  addLineWidget: (line, node, options)->
    if cm = @get('codeMirror')
      return cm.addLineWidget(line, node, options)

  readOnlyDidChange: (->
    if cm = @get 'codeMirror'
      ro = @get 'readOnly'
      cm.setOption 'readOnly', if ro then 'nocursor' else false
  ).observes 'readOnly'

  modeDidChange: (->
    if cm = @get 'codeMirror'
      cm.setOption 'mode', @get 'mode'
      cm.setOption 'lint', @get 'lintableMode'
  ).observes 'mode'

  tabSizeDidChange: (->
    if cm = @get 'codeMirror'
      tabSize = @get 'tabSize'
      cm.setOption 'tabSize', tabSize
      cm.setOption 'indentUnit', tabSize
  ).observes 'tabSize'

  softTabsDidChange: (->
    if cm = @get 'codeMirror'
      cm.setOption 'indentWithTabs', !@get 'softTabs'
  ).observes 'softTabs'

  themeDidChange: (->
    if cm = @get 'codeMirror'
      cm.setOption 'theme', @get('theme')
  ).observes 'theme'

  wrapLinesDidChange: (->
    if cm = @get 'codeMirror'
      cm.setOption 'lineWrapping', @get('wrapLines')
  ).observes 'wrapLines'

  highlightLineDidChange: (->
    if cm = @get 'codeMirror'
      cm.setOption 'styleActiveLine', @get('highlightLine')
  ).observes 'highlightLine'

  showLineNumbersDidChange: (->
    if cm = @get 'codeMirror'
      if @get('showLineNumbers')
        # Reset folding gutters options otherwise the fold gutter will appear
        # to the left of the line number gutter.
        cm.operation =>
          cm.setOption 'lineNumbers', true
          cm.setOption 'foldGutter', cm.getOption('foldGutter')
          cm.setOption 'foldOptions', cm.getOption('foldOptions')
          cm.setOption 'gutters', ['CodeMirror-linenumbers', @get('foldGutterClass')]
      else
        cm.setOption 'lineNumbers', false
  ).observes 'showLineNumbers'

  rulerColumnDidChange: (->
    if cm = @get 'codeMirror'
      col = @get('rulerColumn')
      if col > 0
        cm.setOption 'rulers', [{ column: col }]
      else
        cm.setOption 'rulers', null
  ).observes 'rulerColumn'

  showTrailingSpaceDidChange: (->
    if cm = @get 'codeMirror'
      cm.setOption 'showTrailingSpace', @get('showTrailingSpace')
  ).observes 'showTrailingSpace'

  matchBracketsDidChange: (->
    if cm = @get 'codeMirror'
      cm.setOption 'matchBrackets', @get('matchBrackets')
  ).observes 'matchBrackets'

  autoCloseBracketsDidChange: (->
    if cm = @get 'codeMirror'
      cm.setOption 'autoCloseBrackets', @get('autoCloseBrackets')
  ).observes 'autoCloseBrackets'

  keybindingsDidChange: (->
    if cm = @get 'codeMirror'
      cm.setOption 'keyMap', @get('keybindings')
  ).observes 'keybindings'

  textDidChange: (->
    if cm = @get 'codeMirror'
      if cm.getValue() != (text = @get 'text')
        cm.setValue text
  ).observes 'text'

  wrapperStylingDidChange: (->
    if cm = @get 'codeMirror'
      cm.getWrapperElement()?.setAttribute('style', @get('wrapperStyling'))
      cm.refresh()
  ).observes 'wrapperStyling'

  _bootstrapCodeMirror: ->
    cm = CodeMirror @get('domTarget'),
      lint              : @get 'lintableMode'
      keyMap            : @get 'keybindings'
      theme             : @get 'theme'
      mode              : @get 'mode'
      tabSize           : @get 'tabSize'
      indentUnit        : @get 'tabSize'
      indentWithTabs    : !@get 'softTabs'
      lineWrapping      : @get 'wrapLines'
      styleActiveLine   : @get 'highlightLine'
      lineNumbers       : @get 'showLineNumbers'
      showTrailingSpace : @get 'showTrailingSpace'
      matchBrackets     : @get 'matchBrackets'
      autoCloseBrackets : @get 'autoCloseBrackets'
      foldGutter        : { gutter: @get('foldGutterClass') }
      foldOptions       : { widget: '\u2026', scanUp: true, minFoldSize: 2 }
      gutters           : ['CodeMirror-linenumbers', @get('foldGutterClass')]
      value             : @get 'text'
      styleSelectedText : true # Selected text gets '.CodeMirror-selectedtext' class.
      showCursorWhenSelecting: true
      highlightSelectionMatches: true
      viewportMargin: 2
      workTime: 200
      workDelay: 300
      dragDrop: false

    if rulerColumn = @get 'rulerColumn'
      cm.setOption 'rulers', [{ column: rulerColumn }]

    @_setupExtraKeys(cm)
    @_overrideKeys(cm)
    CodeMirror.keyMap['vim'].fallthrough = 'default'

    cm.on 'change', (cm, data) =>
      if @get('text') != (content = cm.getValue())
        @set 'text', content

    cm.on 'gutterClick', (cm, line, gutter, e) ->
      return if gutter != 'CodeMirror-linenumbers'

      others = []
      if e.ctrlKey || e.metaKey
        others = cm.listSelections()
      from = line
      to = line + 1

      update = ->
        others.push
          anchor: CodeMirror.Pos(from, 0)
          head: CodeMirror.Pos(to, 0)
        cm.setSelections(others, others.length - 1, origin: '*mouse')
      update()

      move = (e) ->
        curLine = cm.lineAtHeight(e.clientY, 'client')
        if (curLine != to)
          to = curLine
          update()

      up = ->
        window.removeEventListener('mouseup', up)
        window.removeEventListener('mousemove', move)

      window.addEventListener('mouseup', up)
      window.addEventListener('mousemove', move)

    @set 'codeMirror', cm

  _setupExtraKeys: (cm) ->
    if App.util.IsMac
      cm.addKeyMap(@get('macExtraKeys'))
    else
      cm.addKeyMap(@get('pcExtraKeys'))

  _overrideKeys: (cm) ->
    overrides = if App.util.IsMac then @get('macOverrideKeys') else @get('pcOverrideKeys')
    submap = if App.util.IsMac then 'macDefault' else 'pcDefault'
    _.each overrides, (key) ->
      delete(CodeMirror.keyMap[submap][key])

klass.reopenClass
  SETTINGS: [
    'softTabs'
    'tabSize'
    'theme'
    'wrapLines'
    'highlightLine'
    'showLineNumbers'
    'rulerColumn'
    'showTrailingSpace'
    'matchBrackets'
    'autoCloseBrackets'
    'keybindings'
    'removeTrailingWhitespaceOnSave'
    'fontSize'
  ]
