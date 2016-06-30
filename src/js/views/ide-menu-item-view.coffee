App.IdeMenuItemView = Em.View.extend
  templateName: 'ide/menu-item'
  tagName: 'li'
  classNameBindings: ['content.separator:separator', 'content.disabled:disabled', 'content.hide:hide', 'content.submenu:dropdown-submenu']
  content: null

  didInsertElement: ->
    @_super()
    this.bindMousetrapKey()
    this.bindCodeMirrorKey()

  willDestroyElement: ->
    @_super()
    this.unbindMousetrapKey()
    this.unbindCodeMirrorKey()

  click: ->
    content = @get 'content'
    return false if content.get('separator') || content.get('disabled')
    unless content.get 'url'
      content.get('callback').call(content, @get 'controller')
    #Mp.track content.get('track')
    true

  bindMousetrapKey: ->
    if key = @get 'content.key'
      Mousetrap.bind key, (event) =>
        this.click()
        false

  unbindMousetrapKey: ->
    if key = @get 'content.key'
      Mousetrap.unbind key

  bindCodeMirrorKey: ->
    if key = @get 'content.codeMirrorKey'
      fallthrough = CodeMirror.keyMap.default.fallthrough
      if _.isString fallthrough
        CodeMirror.keyMap.default.fallthrough = [fallthrough, 'aio']
      else
        if fallthrough && fallthrough[1] != 'aio'
          fallthrough.splice 1, 0, 'aio'
      CodeMirror.keyMap.aio ||= {}
      for k in key
        CodeMirror.keyMap.aio[k] = =>
          this.click()

  unbindCodeMirrorKey: ->
    if key = @get 'content.codeMirrorKey'
      delete CodeMirror.keyMap.aio[k] for k in key

