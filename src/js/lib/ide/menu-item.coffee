macKeyNames =
  command: "\u2318"
  ctrl: "\u2303"
  shift: "\u21e7"
  option: "\u2325"
  alt: "Alt"
  tab: "\u21E5"
  backspace: "\u232B"
  escape: "\u238B"

pcKeyNames =
  command: "Windows"
  ctrl: "Ctrl"
  shift: "Shift"
  option: "Alt"
  alt: "Alt"
  tab: "Tab"
  backspace: "Backspace"
  escape: "Escape"


keySplit = /'.*?'|".*?"|[^+]+/g

App.MenuItem = Em.Object.extend
  name: null
  macKey: null
  pcKey: null
  chromeMacKey: null
  chromePcKey: null
  url: null
  target: null
  track: null
  submenu: null
  checked: false
  callback: Em.K
  separator: false
  disabled: false
  hide: false

  key: (->
    if App.get 'chromeApp'
      if App.util.IsMac
        @get 'chromeMacKey'
      else
        @get 'chromePcKey'
    else
      if App.util.IsMac
        @get 'macKey'
      else
        @get 'pcKey'
  ).property 'App.chromeApp', 'chromeMacKey', 'chromePcKey', 'macKey', 'pcKey'

  keyLabel: (->
    isMac = App.util.IsMac
    if key = @get 'key'
      key = key[0] if _.isArray key

      _.map(key.match(keySplit), (k) ->
        if match = k.match(/['"](.+)['"]/)
          k = match[1]
        k = (if isMac then macKeyNames else pcKeyNames)[k] || k
        k = k.charAt(0).toUpperCase() + k.slice(1)
      ).join(if isMac then ' ' else '+')
  ).property 'key'

  codeMirrorKey: (->
    if keys = @get 'key'
      keys = [keys] if _.isString keys
      _.map keys, (key) ->
        _.map(key.match(keySplit), (k) ->
          if match = k.match(/['"](.+)['"]/)
            k = match[1]
          k = switch k
            when 'command'
              'Cmd'
            when 'option'
              'Alt'
            when 'return'
              'Enter'
            when 'pageup'
              'PageUp'
            when 'pagedown'
              'PageDown'
            when '+'
              '='
            else
              k
          k.charAt(0).toUpperCase() + k.slice(1)
        ).join '-'
  ).property 'key'
