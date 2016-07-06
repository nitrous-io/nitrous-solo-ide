App.IdeSearchView = Em.View.extend
  templateName: 'search'
  classNames: ['ide-search-view']
  classNameBindings: ['document.active']

  document: null

  actions:
    didClickResult: (filename, line) ->
      # filename will be relative to home directory
      path = App.Path.create absolutePath: filename
      if sidebar = App.get('router.ideSidebarController')
        sidebar.openPath path,
          done: (doc) ->
            Em.run.next ->
              doc.set('goToLine', line.lineNumber)
          source: 'search'
