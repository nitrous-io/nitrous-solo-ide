menu = (name, items) -> App.Menu.create(name: name, items: items)
menuItem = (name, attrs={}) ->
  attrs.name = name
  App.MenuItem.createWithMixins(attrs)
separator = App.MenuItem.create(separator: true)

rulerMenu = menu 'Ruler', [
  menuItem 'None',
    callback: (controller) ->
      controller.viewSetRulerColumn(0)
    checked: (->
      !App.get('router.ideEditorController.rulerColumn')
    ).property 'App.router.ideEditorController.rulerColumn'
  separator
].concat _.map [
  78
  80
  100
  120
], (column) ->
  menuItem column,
    callback: (controller) ->
      controller.viewSetRulerColumn column
    checked: (->
      column == App.get('router.ideEditorController.rulerColumn')
    ).property 'App.router.ideEditorController.rulerColumn'

isOwner = (container) ->
  App.get('user.id') == container.user_id

themesMenu = menu 'Themes', _.map [
  { name: 'solarized dark', label: 'Solarized Dark' }
  { name: 'vibrant-ink', label: 'Vibrant Ink' }
  { name: 'monokai-dark-soda', label: 'Monokai Dark Soda'}
  { name: 'base16-dark', label: 'Base16 Dark' }
  { name: 'base16-eighties-dark', label: 'Base16 Eighties Dark' }
  { name: 'base16-ocean-dark', label: 'Base16 Ocean Dark' }
  { name: '---' }
  { name: 'solarized light', label: 'Solarized Light' }
  { name: 'github', label: 'GitHub' }
  { name: 'visual-studio', label: 'Visual Studio'}
  { name: 'base16-light', label: 'Base16 Light' }
  { name: 'base16-eighties-light', label: 'Base16 Eighties Light' }
  { name: 'base16-ocean-light', label: 'Base16 Ocean Light' }
], (theme) ->
  if theme.name == '---'
    separator
  else
    menuItem theme.label,
      callback: (controller) ->
        controller.windowSelectTheme theme.name
      checked: (->
        if currentTheme = App.get('router.ideEditorController.theme')
          currentTheme == theme.name
      ).property 'App.router.ideEditorController.theme'

App.IdeMainMenuView = Em.View.extend
  templateName: 'ide/main-menu'
  elementId: 'ide-main-menu-view'

  previewPortBinding: Em.Binding.oneWay 'App.container.previewPort'
  dashboardURLBinding: Em.Binding.oneWay 'App.dashboardURL'
  userBinding: Em.Binding.oneWay 'App.user'

  previewItems: (->
    [
      menuItem "Port 3000 -- HTTP",
        url: "http://#{App.get 'container.preview_hostname'}"
        target: '_blank'
      menuItem "Port 3000 -- HTTPS",
        url: "https://#{App.get 'container.preview_hostname'}"
        target: '_blank'
      menuItem "Port 4000",
        url: "http://#{App.get 'container.preview_hostname'}:4000"
        target: '_blank'
      menuItem "Port 4567",
        url: "http://#{App.get 'container.preview_hostname'}:4567"
        target: '_blank'
      menuItem "Port 8080",
        url: "http://#{App.get 'container.preview_hostname'}:8080"
        target: '_blank'
      menuItem "Port 8888",
        url: "http://#{App.get 'container.preview_hostname'}:8888"
        target: '_blank'
      separator,
      menuItem 'Preview Help',
        url: 'https://community.nitrous.io/docs/preview-your-app'
        target: '_blank'
    ]
  ).property 'App.container', 'App.container.previewablePorts.@each'

  helpMenuItems: (->
    items = []
    if App.get('container.env.NITROUS_README_URL')
      items.push(
        menuItem 'View README', callback: (controller) ->
          controller.helpNitrousReadme()
        separator
      )
    items.push(
      menuItem 'Help Center',
        url: 'https://community.nitrous.io/docs'
        target: '_blank'
      menuItem 'Web IDE Overview',
        url: 'http://docs.nitrous.io/v1.0/docs/web-ide-overview'
        target: '_blank'
      menuItem 'Nitrous Account Questions',
        url: 'https://community.nitrous.io/docs/billing-pricing-faq'
        target: '_blank'
      separator
      menuItem 'Blog',
        url: 'https://community.nitrous.io/posts'
        target: '_blank'
      menuItem 'Updates',
        url: 'https://community.nitrous.io/posts/tagged/changelog'
        target: '_blank'
    )
    items
  ).property 'App.container', 'App.container.env', 'App.container.env.NITROUS_README_URL'

  menu: (->
    base = [
      menu 'N', [
        menuItem 'About Nitrous', callback: ->
          ui.showModal($('#about-nitrous'))
      ]
      menu 'File', [
        menuItem 'New',
          macKey: 'shift+ctrl+n', pcKey: 'ctrl+alt+n'
          chromeMacKey: ['command+n', 'shift+ctrl+n'], chromePcKey: ['ctrl+n', 'shift+ctrl+n', 'ctrl+alt+n']
          callback: (controller) ->
            controller.fileNew()
        menuItem 'Save',
          macKey: ['command+s', 'shift+ctrl+s'], pcKey: ['ctrl+s', 'ctrl+alt+s']
          chromeMacKey: ['command+s', 'shift+ctrl+s'], chromePcKey: ['ctrl+s', 'ctrl+alt+s']
          disabled: (->
            App.get('router.ideEditorController.hasNoTab') || App.get('router.ideController.opsSocketNotReady')
          ).property 'App.router.ideEditorController.hasNoTab', 'App.router.ideController.opsSocketNotReady'
          callback: (controller) ->
            controller.fileSave()
        separator
        menuItem 'Refresh Tree',
          macKey: 'shift+ctrl+r', pcKey: 'ctrl+alt+r'
          chromeMacKey: ['shift+command+r', 'shift+ctrl+r'], chromePcKey: ['shift+ctrl+r', 'ctrl+alt+r']
          disabledBinding: Em.Binding.oneWay('App.router.ideSidebarController.opsSocketNotReady')
          callback: (controller) ->
            controller.fileRefreshTree()
        menuItem 'Go to File...',
          macKey: 'shift+ctrl+p', pcKey: 'shift+ctrl+p'
          chromeMacKey: ['command+p', 'shift+ctrl+p'], chromePcKey: ['ctrl+p', 'shift+ctrl+p']
          disabledBinding: Em.Binding.oneWay('App.router.ideController.opsSocketNotReady')
          callback: (controller) ->
            controller.fileGoToFile()
        separator
        menuItem 'Close',
          macKey: 'shift+ctrl+w', pcKey: 'ctrl+alt+w'
          chromeMacKey: ['command+w', 'shift+ctrl+w'], chromePcKey: ['ctrl+w', 'shift+ctrl+w', 'ctrl+alt+w']
          callback: (controller) ->
            controller.fileClose()
      ]
      menu 'Edit', [
        menuItem 'Go to Line',
          macKey: 'command+l', pcKey: 'ctrl+l'
          chromeMacKey: 'command+l', chromePcKey: 'ctrl+l'
          disabledBinding: Em.Binding.oneWay('App.router.ideEditorController.hasNoTab')
          callback: (controller) ->
            controller.editGoToLine()
        menuItem 'Go to Definition',
          macKey: 'shift+ctrl+.', pcKey: 'ctrl+alt+.'
          chromeMacKey: ['shift+command+.', 'shift+ctrl+.'],     chromePcKey: ['shift+ctrl+.', 'ctrl+alt+.']
          disabled: (->
            return false if App.get('router.ideEditorController.supportsGoToDefinition')
            true
          ).property 'App.router.ideEditorController.supportsGoToDefinition'
          callback: (controller) ->
            controller.findGoToDefinition()
        separator
        menuItem 'Fold',
          chromeMacKey: 'option+command+[', chromePcKey: 'shift+ctrl+['
          disabledBinding: Em.Binding.oneWay('App.router.ideEditorController.isActiveTabNotAnEditor')
          callback: (controller) ->
            controller.editFoldCode()
        menuItem 'Unfold',
          chromeMacKey: 'option+command+]', chromePcKey: 'shift+ctrl+]'
          disabledBinding: Em.Binding.oneWay('App.router.ideEditorController.isActiveTabNotAnEditor')
          callback: (controller) ->
            controller.editUnfoldCode()
        separator
        menuItem 'Toggle Comment',
          macKey: 'command+/', pcKey: 'ctrl+/'
          chromeMacKey: 'command+/', chromePcKey: 'ctrl+/'
          disabledBinding: Em.Binding.oneWay('App.router.ideEditorController.isActiveTabNotAnEditor')
          callback: (controller) ->
            controller.editToggleComment()
        menuItem 'Split Selection into Lines',
          macKey: 'shift+ctrl+l', pcKey: 'shift+ctrl+l'
          chromeMacKey: ['shift+command+l', 'shift+ctrl+l'], chromePcKey: 'shift+ctrl+l'
          disabledBinding: Em.Binding.oneWay('App.router.ideEditorController.isActiveTabNotAnEditor')
          callback: (controller) ->
            controller.editSplitSelectionIntoLines()
        separator
        menuItem 'Auto-close Brackets & Quotes',
          callback: (controller) ->
            controller.editToggleAutoCloseBrackets()
          checkedBinding: Em.Binding.oneWay('App.router.ideEditorController.autoCloseBrackets')
        menuItem 'Remove Trailing Whitespace on Save',
          callback: (controller) ->
            controller.editToggleRemoveTrailingWhitespaceOnSave()
          checkedBinding: Em.Binding.oneWay('App.router.ideEditorController.removeTrailingWhitespaceOnSave')
        separator
        menuItem 'Use Vim Key Bindings',
          callback: (controller) ->
            if @get('checked')
              controller.editSetKeybindings('default')
            else
              controller.editSetKeybindings('vim')
          checked: (->
            'vim' == App.get('router.ideEditorController.keybindings')
          ).property 'App.router.ideEditorController.keybindings'
      ]
      menu 'Find', [
        menuItem 'Find',
          macKey: 'command+f', pcKey: 'ctrl+f'
          chromeMacKey: 'command+f', chromePcKey: 'ctrl+f'
          disabledBinding: Em.Binding.oneWay('App.router.ideEditorController.isActiveTabNotAnEditor')
          callback: (controller) ->
            controller.findFind()
        separator
        menuItem 'Find Next',
          macKey: 'command+g', pcKey: 'ctrl+g'
          chromeMacKey: 'command+g', chromePcKey: ['ctrl+g', 'f3']
          disabledBinding: Em.Binding.oneWay('App.router.ideEditorController.isActiveTabNotAnEditor')
          callback: (controller) ->
            controller.findFindNext()
        menuItem 'Find Previous',
          macKey: 'shift+command+g', pcKey: 'shift+ctrl+g'
          chromeMacKey: 'shift+command+g', chromePcKey: ['shift+ctrl+g', 'shift+f3']
          disabledBinding: Em.Binding.oneWay('App.router.ideEditorController.isActiveTabNotAnEditor')
          callback: (controller) ->
            controller.findFindPrevious()
        menuItem 'Select Next',
          macKey: 'ctrl+d', pcKey: 'ctrl+d'
          chromeMacKey: ['command+d', 'ctrl+d'], chromePcKey: 'ctrl+d'
          disabledBinding: Em.Binding.oneWay('App.router.ideEditorController.isActiveTabNotAnEditor')
          callback: (controller) ->
            controller.findSelectNext()
        separator
        menuItem 'Replace',
          macKey: 'option+command+f', pcKey: 'shift+ctrl+h'
          chromeMacKey: ['option+command+f', 'ctrl+h'], chromePcKey: 'ctrl+h'
          disabledBinding: Em.Binding.oneWay('App.router.ideEditorController.isActiveTabNotAnEditor')
          callback: (controller) ->
            controller.findReplace()
        separator
        menuItem 'Find in Files...',
          macKey: 'shift+command+f', pcKey: 'shift+ctrl+f'
          chromeMacKey: 'shift+command+f', chromePcKey: 'shift+ctrl+f'
          disabledBinding: Em.Binding.oneWay('App.router.ideController.opsSocketNotReady')
          disabled: true
          callback: (controller) ->
            controller.findFindInFiles()
        separator
        menuItem 'Reveal in sidebar',
          macKey: 'shift+ctrl+j', pcKey: 'ctrl+alt+j'
          chromeMacKey: ['shift+command+j', 'shift+ctrl+j'],     chromePcKey: ['shift+ctrl+j', 'ctrl+alt+j']
          disabledBinding: Em.Binding.oneWay('App.router.ideEditorController.hasNoTab')
          callback: (controller) ->
            controller.revealInSidebar()
      ]
      menu 'View', [
        menuItem 'Split Editor Pane Vertically',
          macKey: 'shift+ctrl+8', pcKey: 'shift+ctrl+8'
          chromeMacKey: 'shift+ctrl+8', chromePcKey: 'shift+ctrl+8'
          callback: (controller) ->
            controller.viewSplitEditorPaneVertically()
        menuItem 'Split Editor Pane Horizontally',
          macKey: 'shift+ctrl+9', pcKey: 'shift+ctrl+9'
          chromeMacKey: 'shift+ctrl+9', chromePcKey: 'shift+ctrl+9'
          callback: (controller) ->
            controller.viewSplitEditorPaneHorizontally()
        menuItem 'Close Editor Pane',
          macKey: "shift+ctrl+'", pcKey: "shift+ctrl+'"
          chromeMacKey: "shift+ctrl+'", chromePcKey: "shift+ctrl+'"
          callback: (controller) ->
            controller.viewCloseEditorPane()
        separator
        menuItem 'Ruler', submenu: rulerMenu
        menuItem 'Wrap Long Lines',
          callback: (controller) ->
            controller.viewToggleWrapLines()
          checkedBinding: Em.Binding.oneWay('App.router.ideEditorController.wrapLines')
        separator
        menuItem 'Show Line Numbers',
          callback: (controller) ->
            controller.viewToggleLineNumbers()
          checkedBinding: Em.Binding.oneWay('App.router.ideEditorController.showLineNumbers')
        menuItem 'Highlight Line',
          callback: (controller) ->
            controller.viewToggleHighlightLine()
          checkedBinding: Em.Binding.oneWay('App.router.ideEditorController.highlightLine')
        menuItem 'Highlight Matching Brackets',
          callback: (controller) ->
            controller.viewToggleMatchBrackets()
          checkedBinding: Em.Binding.oneWay('App.router.ideEditorController.matchBrackets')
        menuItem 'Show Trailing Whitespace',
          callback: (controller) ->
            controller.viewToggleTrailingSpace()
          checkedBinding: Em.Binding.oneWay('App.router.ideEditorController.showTrailingSpace')
        separator
        menuItem 'Increase Font Size',
          macKey: 'shift+ctrl+"+"', pcKey: 'shift+ctrl+"+"'
          chromeMacKey: ['shift+ctrl+"+"'], chromePcKey: 'shift+ctrl+"+"'
          disabledBinding: Em.Binding.oneWay('App.router.ideEditorController.isActiveTabNotAnEditor')
          callback: (controller) ->
            controller.viewIncreaseFontSize()
        menuItem 'Decrease Font Size',
          macKey: 'shift+ctrl+-', pcKey: 'shift+ctrl+-'
          chromeMacKey: ['shift+ctrl+-'], chromePcKey: 'shift+ctrl+-'
          disabledBinding: Em.Binding.oneWay('App.router.ideEditorController.isActiveTabNotAnEditor')
          callback: (controller) ->
            controller.viewDecreaseFontSize()
        menuItem 'Reset Font Size',
          macKey: 'shift+ctrl+0', pcKey: 'shift+ctrl+0'
          chromeMacKey: ['shift+ctrl+0'], chromePcKey: 'shift+ctrl+0'
          disabledBinding: Em.Binding.oneWay('App.router.ideEditorController.isActiveTabNotAnEditor')
          callback: (controller) ->
            controller.viewResetFontSize()
      ]
      menu 'Window', [
        menuItem 'Editor Theme', submenu: themesMenu
        separator
        menuItem 'Select Next Tab',
          macKey: 'shift+ctrl+]', pcKey: 'shift+ctrl+]'
          chromeMacKey: ['ctrl+tab', 'shift+command+]'], chromePcKey: 'ctrl+tab'
          callback: (controller) ->
            controller.windowSelectNextTab()
        menuItem 'Select Previous Tab',
          macKey: 'shift+ctrl+[', pcKey: 'shift+ctrl+['
          chromeMacKey: ['shift+ctrl+tab', 'shift+command+['], chromePcKey: 'shift+ctrl+tab'
          callback: (controller) ->
            controller.windowSelectPreviousTab()
        separator
        menuItem 'Focus Console',
          macKey: 'shift+ctrl+c', pcKey: 'ctrl+alt+c'
          chromeMacKey: ['command+t', 'shift+ctrl+c'], chromePcKey: ['ctrl+t', 'shift+ctrl+t', 'ctrl+alt+c']
          callback: (controller) ->
            controller.windowFocusConsole()
        menuItem 'Toggle Minimize Console',
          macKey: 'shift+ctrl+m', pcKey: 'ctrl+alt+m'
          chromeMacKey: 'shift+ctrl+m', chromePcKey: 'ctrl+alt+m'
          callback: (controller) ->
            controller.windowToggleMinimizeConsole()
        menuItem 'Toggle Full Screen Console',
          macKey: 'shift+ctrl+f', pcKey: 'ctrl+alt+f'
          chromeMacKey: 'shift+ctrl+f', chromePcKey: 'ctrl+alt+f'
          callback: (controller) ->
            controller.windowToggleFullScreenConsole()
        separator
        menuItem 'Show Active Files',
          hide: (->
            return false if App.get('fileTreeHidden')
            App.get('router.ideSidebarController.showActiveFilesPane')
          ).property('App.fileTreeHidden', 'App.router.ideSidebarController.showActiveFilesPane')
          callback: (controller)->
            controller.windowShowActiveFiles()
        menuItem 'Hide Active Files',
          hide: (->
            return true if App.get('fileTreeHidden')
            !App.get('router.ideSidebarController.showActiveFilesPane')
          ).property('App.fileTreeHidden', 'App.router.ideSidebarController.showActiveFilesPane')
          callback: (controller)->
            controller.windowHideActiveFiles()
        menuItem 'Hide File Tree',
          hideBinding: Em.Binding.oneWay('App.fileTreeHidden')
          callback: (controller) ->
            controller.windowHideFileTree()
        menuItem 'Show File Tree',
          hide: (->
            !App.get('fileTreeHidden')
          ).property('App.fileTreeHidden')
          callback: (controller) ->
            controller.windowShowFileTree()
      ]
      menu 'Preview', @get('previewItems')
      menu 'Git', [
        menuItem 'Clone from GitHub',
          callback: (controller) ->
            controller.gitCloneFromGitHub()
      ]
    ]

    base.push(menu 'Collaborate', [
      menuItem 'Invite Collaborators',
        disabled: (->
          !App.get('host.slug') || !App.get('container.slug') || !isOwner(App.get('container'))
        ).property 'App.host.slug', 'App.container.slug', 'App.container'

        url: "/app/#/dashboard/workstations/#{App.get('host.slug')}/projects/#{App.get('container.slug')}/collaborators"
        target: '_blank'
    ])

    base.push(menu 'PubStorm', [
      menuItem 'Getting Started Guide',
        url: 'http://help.pubstorm.com/getting-started/getting-started'
        target: '_blank'
      menuItem 'Adding a Custom Domain',
        url: 'http://help.pubstorm.com/getting-started/custom-domains'
        target: '_blank'
    ])

    base.push(menu 'Help', @get('helpMenuItems'))

    base
  ).property('previewItems', 'helpMenuItems')

  currentYear: (->
    new Date().getFullYear()
  ).property()

  actions:
    closeAboutDialog: ->
      ui.hideModal(@$('#about-nitrous'))
