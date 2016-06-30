CodeMirror = require('../vendor/codemirror/lib/codemirror')
require '../vendor/codemirror/addon/mode/simple'
require '../vendor/codemirror/mode/clike/clike'
require '../vendor/codemirror/mode/clojure/clojure'
require '../vendor/codemirror/mode/coffeescript/coffeescript'
require '../vendor/codemirror/mode/css/css'
require '../vendor/codemirror/mode/diff/diff'
require '../vendor/codemirror/mode/erlang/erlang'
require '../vendor/codemirror/mode/groovy/groovy'
require '../vendor/codemirror/mode/go/go'
require '../vendor/codemirror/mode/handlebars/handlebars'
require '../vendor/codemirror/mode/haskell/haskell'
require '../vendor/codemirror/mode/htmlembedded/htmlembedded'
require '../vendor/codemirror/mode/htmlmixed/htmlmixed'
require '../vendor/codemirror/mode/jade/jade'
require '../vendor/codemirror/mode/julia/julia'
require '../vendor/codemirror/mode/javascript/javascript'
require '../vendor/codemirror/mode/jinja2/jinja2'
require '../vendor/codemirror/mode/jsx/jsx'
require '../vendor/codemirror/mode/lua/lua'
require '../vendor/codemirror/mode/markdown/markdown'
require '../vendor/codemirror/mode/mllike/mllike'
require '../vendor/codemirror/mode/perl/perl'
require '../vendor/codemirror/mode/php/php'
require '../vendor/codemirror/mode/python/python'
require '../vendor/codemirror/mode/r/r'
require '../vendor/codemirror/mode/ruby/ruby'
require '../vendor/codemirror/mode/rust/rust'
require '../vendor/codemirror/mode/sass/sass'
require '../vendor/codemirror/mode/scheme/scheme'
require '../vendor/codemirror/mode/shell/shell'
require '../vendor/codemirror/mode/stylus/stylus'
require '../vendor/codemirror/mode/sql/sql'
require '../vendor/codemirror/mode/xml/xml'
require '../vendor/codemirror/mode/yaml/yaml'
require '../vendor/codemirror/mode/haml/haml'
require '../vendor/codemirror/mode/slim/slim'

require '../vendor/codemirror/keymap/vim'
require '../vendor/codemirror/keymap/sublime'

require '../vendor/codemirror/addon/mode/multiplex'
require '../vendor/codemirror/addon/comment/comment'
require '../vendor/codemirror/addon/display/rulers'
require '../vendor/codemirror/addon/edit/matchbrackets'
require '../vendor/codemirror/addon/edit/closebrackets'
require '../vendor/codemirror/addon/edit/trailingspace'
require '../vendor/codemirror/addon/selection/active-line'
require '../vendor/codemirror/addon/selection/mark-selection'
require '../vendor/codemirror/addon/search/searchcursor'
require '../vendor/codemirror/addon/search/match-highlighter'
require '../vendor/codemirror/addon/hint/show-hint'
require '../vendor/codemirror/addon/hint/anyword-hint'
require '../vendor/codemirror/addon/hint/css-hint'
require '../vendor/codemirror/addon/hint/xml-hint'
require '../vendor/codemirror/addon/hint/html-hint'
require '../vendor/codemirror/addon/hint/javascript-hint'
require '../vendor/codemirror/addon/fold/foldcode'
require '../vendor/codemirror/addon/fold/foldgutter'
require '../vendor/codemirror/addon/fold/brace-fold'
require '../vendor/codemirror/addon/fold/comment-fold'
require '../vendor/codemirror/addon/fold/indent-fold'
require '../vendor/codemirror/addon/fold/xml-fold'

CodeMirror.defineMIME 'text/x-jinja2', name: 'jinja2'

CodeMirror.MODES =
  'text/plain'                : 'Plain Text'
  'text/x-csrc'               : 'C'
  'text/x-c++src'             : 'C++'
  #'text/x-csharp'
  'text/x-clojure'            : 'Clojure'
  'text/x-coffeescript'       : 'CoffeeScript'
  'text/css'                  : 'CSS'
  'text/x-diff'               : 'Diff'
  'text/x-erlang'             : 'Erlang'
  #'application/x-aspx'
  'text/x-go'                 : 'Go'
  'text/x-groovy'             : 'Groovy'
  'text/x-haml'               : 'Haml'
  'text/x-handlebars-template': 'Handlebars'
  'text/x-haskell'            : 'Haskell'
  'text/html'                 : 'HTML'
  'application/x-ejs'         : 'HTML (ejs)'
  'application/x-erb'         : 'HTML (erb)'
  'text/x-jade'               : 'Jade'
  'text/x-java'               : 'Java'
  'text/javascript'           : 'JavaScript'
  'text/x-jinja2'             : 'Jinja2'
  'text/jsx'                  : 'JSX'
  'application/json'          : 'JSON'
  'application/x-jsp'         : 'JSP'
  'text/x-julia'              : 'Julia'
  'text/x-less'               : 'LESS'
  'text/x-lua'                : 'Lua'
  'text/x-markdown'           : 'Markdown'
  'text/x-ocaml'              : 'OCaml'
  'text/x-perl'               : 'Perl'
  'application/x-httpd-php'   : 'PHP'
  'text/x-python'             : 'Python'
  'text/x-rsrc'               : 'R'
  'text/x-ruby'               : 'Ruby'
  'text/x-rustsrc'            : 'Rust'
  'text/x-sass'               : 'Sass'
  'text/x-scala'              : 'Scala'
  'text/x-scheme'             : 'Scheme'
  'text/x-scss'               : 'SCSS'
  'text/x-sh'                 : 'Shell Script'
  'text/x-sql'                : 'SQL'
  'text/x-slim'               : 'Slim'
  'text/x-styl'               : 'Stylus'
  'application/typescript'    : 'TypeScript'
  'application/xml'           : 'XML'
  'text/x-yaml'               : 'YAML'

(CodeMirror.MODES_ARRAY ||= []).push(mode: k, name: v) for k, v of CodeMirror.MODES

CodeMirror.MODES_WITH_LINTING =[
  'text/javascript'
  'application/json'
]

CodeMirror.commands.goMatchingBracket = (cm) ->
  cur = cm.getCursor()
  match = cm.findMatchingBracket?(line: cur.line, ch: cur.ch)
  return false if !match
  # If cursor is outside of brackets, stay on the outside.
  # E.g. if cursor is before opening bracket, move to after the closing bracket.
  if match.from.line < cur.line || (match.from.line == cur.line && match.from.ch < cur.ch)
    cm.extendSelection(match.to)
  else
    cm.extendSelection(line: match.to.line, ch: match.to.ch + 1)

CodeMirror.commands.unfold = (cm) ->
  cm.foldCode(cm.getCursor(), null, 'unfold');

CodeMirror.commands.insertLineBefore = (cm) ->
  cm.operation ->
    cm.execCommand('goLineStartSmart')
    cm.execCommand('newlineAndIndent')
    cm.setCursor(cm.getCursor().line - 1)
    cm.indentLine(cm.getCursor().line, null, true)

CodeMirror.commands.insertLineAfter = (cm) ->
  cm.operation ->
    cm.execCommand('goLineEnd')
    cm.replaceSelection("\n", 'end', '+input')
    cm.indentLine(cm.getCursor().line, null, true)

CodeMirror.commands.smartTab = (cm) ->
  # If there is a selection, pressing Tab will indent it, otherwise,
  # just insert a tab character or spaces.
  if cm.getSelection().length
    cm.execCommand('indentMore')
  else
    if cm.getOption('indentWithTabs')
      cm.execCommand('insertTab')
    else
      spaces = Array(cm.getOption('indentUnit') + 1).join(' ')
      cm.replaceSelection spaces, 'end', '+input'

window.CodeMirror = CodeMirror
module.exports = CodeMirror;
