PluginBase = require './base'
require './global-ruby'

klass = class Ruby extends PluginBase
  IGNORE_SYMBOLS = ['def', 'end', 'class', 'do', 'if', 'else']

  DEFAULT_GEMS = [
    'rails',
    'actionmailer',
    'actionview',
    'actionpack',
    'activerecord',
    'activejob',
    'activemodel',
    'activesupport',
    'sinatra',
  ]

  HINT_WORDS = [
    'BEGIN'
    'END'
    'alias'
    'and'
    'begin'
    'break'
    'case'
    'class'
    'def'
    'defined?'
    'do'
    'else'
    'elsif'
    'end'
    'ensure'
    'false'
    'for'
    'if'
    'module'
    'next'
    'nil'
    'not'
    'or'
    'raise'
    'redo'
    'require'
    'rescue'
    'retry'
    'return'
    'self'
    'super'
    'then'
    'true'
    'undef'
    'unless'
    'until'
    'when'
    'while'
    'yield'
    '__FILE__'
    '__LINE__'
  ]

  triggerCtagsUpdate: ->
    return unless @document?.isOTMaster()

    @globalPlugin.triggerCtagsUpdate(@getRootPath().get('absolutePath'))

  afterInitialize: ->
    super
    @triggerCtagsUpdate()

  afterSetCodeMirror: ->
    @processFile()

  afterSave: (context)->
    @triggerCtagsUpdate()
    @processFile()

  afterChanges: (changes)->
    for change in changes
      if change.origin?.match(/delete/) && change.from.line <= @definitionEndsAt
        @processFile()
        break

      # process the existing text before asking CM
      process = false
      if lines = change.text
        for line in lines
          if line.match(/require|class/)
            process = true
            break

      if process
        @processFile()
        break

      # okay finally ask for any changes
      start = {line: change.from.line, ch: 0}
      ending = change.to
      text = @codeMirror.getRange(start, ending)
      if text.match(/require|class/)
        @processFile()
        break

  handleFileChanged: (change, location)->
    if location && location.match(/\.rb$/)
      @triggerCtagsUpdate()

  handleDirChanged: ->
    @triggerCtagsUpdate()

  processFile: ->
    @definitionEndsAt = 0
    @requirements = []
    @inheritance = []
    @className = null
    @eachLine (line) =>
      # look for the class MyClass < BaseClass definition of a file
      # parsing out the inheritance (base class)
      definition = line.text.match(/class\s+([^ ]+)\s+(?:<\s+([^ ]+))?$/)
      if definition
        @className = definition[1]
        if baseClass = definition[2]
          @inheritance = baseClass.split("::")

        @definitionEndsAt = line.lineNo()
        return true # finished

      requires = line.text.match(/require ["']([^'"]+)["']/)
      if requires
        @requirements.push requires[1]
        @definitionEndsAt = line.lineNo()

      return false

  cTagsLocation: ->
    @getRootPath().get('absolutePath') + "/.ruby-tags"

  ctagsUpdated: ->
    if exec = @afterCtagsUpdated
      @afterCtagsUpdated = null
      exec()

  autocomplete: (cm, callback, options)->
    options ||= {}

    cursor = cm.getCursor()
    line = cm.getRange({line: cursor.line, ch: 0}, cursor)
    unless line && line.length
      callback(list: [])
      return

    line = line.trim()
    if (reqDef = line.match(/require ['"]([^"']+)['"]?/))
      return @autocompleteRequire(reqDef, cursor, cm, callback, options)

    @autocompleteLine(line, cursor, cm, callback, options)

  autocompleteRequire: (reqDef, cursor, cm, callback, options)->
    if @afterCtagsUpdated
      return

    return unless reqDef[1].length >= 2
    @searchCTags "(\t|lib/)#{reqDef[1]}", (err, cmdErr, stdout, stderr) =>
      if stderr && stderr.match(/\.ruby-tags:\s+No\s+such/)
        @afterCtagsUpdated = =>
          @autocompleteRequire(reqDef, cursor, cm, callback, options)
        @triggerCtagsUpdate()
        return

      results = []
      @parseCTags stdout, (varName, path, allParts)=>
        if (reqName = path.match(/lib\/(.+)\.rb/)) && results.indexOf(reqName[1]) == -1
          results.push reqName[1]
        else if path.startsWith(reqDef[1])
          reqName = path.match(/^(.+)\.rb/)
          if results.indexOf(reqName[1]) == -1
            results.push reqName[1]
      results.sort()
      callback(_handlers: options.handlers, list: results, to: cursor, from: {line: cursor.line, ch: (cursor.ch - reqDef[1].length)})

  autocompleteLine: (line, cursor, cm, callback, options)->
    # look for symbols after a space, period or colon
    # if we are doing a class definition with a base class
    # autocomplete on the base class
    symbols = line.match(/(?:class\s+(\w+)\s+\<)?([^\[\]{}\|(),; .:'"\/?!%\^*\-@]+)$/)
    unless symbols
      callback(_handlers: options.handlers, list: [])
      return

    newClass = null
    symbol = symbols[0]
    if symbols.length == 3
      newClass = symbols[1]
      symbol = symbols[2]

    return if @ignoredSymbol(symbol)

    # store featured results
    localHints = CodeMirror.hint.auto(@codeMirror, {})
    suggestedResults = []
    if localHints?.list
      for hint in localHints?.list
        if hint != symbol
          suggestedResults.push hint

    for word in HINT_WORDS
      if word != symbol && word.indexOf(symbol) == 0 && suggestedResults.indexOf(word) == -1
        suggestedResults.push word

    # let local process run
    suggestedResults.sort()
    callback(_handlers: options.handlers, list: suggestedResults, to: cursor, from: {line: cursor.line, ch: (cursor.ch - symbol.length)})

    results = [] # all other results
    if @afterCtagsUpdated
      return

    if symbol.length >= 2
      @searchCTags "^#{symbol}", (err, cmdErr, stdout, stderr) =>
        if stderr && stderr.match(/\.ruby-tags:\s+No\s+such/)
          @afterCtagsUpdated = =>
            @autocompleteLine(line, cursor, cm, callback, options)
          @triggerCtagsUpdate()
          return

        @parseCTags stdout, (varName, path, allParts)=>
          # no point suggesting the same thing
          if symbol == varName
            return

          if suggestedResults.indexOf(varName) == -1
            definition = allParts[4]
            addToResults = true

            if definition && defClassList = definition.match(/class\:(.+)$/)
              defClass = defClassList[1]
              for name in @inheritance
                if defClass.indexOf(name) != -1
                  addToResults = false
                  suggestedResults.push varName
                  if (existing = results.indexOf(varName)) != -1
                    results.splice(existing, 1)
                  break

            if addToResults
              # only include required gems (or common globals)
              if (gemName = path.match(/\.bundle\/gems\/(\w+)-\d/)?[1])
                addToResults = @requiredGem(gemName)

              if addToResults && (results.indexOf(varName) == -1)
                results.push varName

        finalList = suggestedResults.concat(results.sort())
        callback(_handlers: options.handlers, list: finalList, to: cursor, from: {line: cursor.line, ch: (cursor.ch - symbol.length)})

  ignoredSymbol: (symbol)->
    IGNORE_SYMBOLS.indexOf(symbol) != -1

  requiredGem: (name)->
    return true if DEFAULT_GEMS.indexOf(name) != -1
    @requirements.indexOf(name) != -1

App.CodePluginsManager.registerCodePlugin "ruby", klass, ["ruby", "text/x-ruby"]
