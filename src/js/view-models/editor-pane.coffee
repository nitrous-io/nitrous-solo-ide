App.EditorPane = Em.ArrayProxy.extend
  tabs: Em.computed.alias 'content'
  left: null
  right: null
  parent: null
  tabWatcher: null

  horizontal: false

  active: (->
    App.get('router.ideEditorController.activePane') == this
  ).property 'App.router.ideEditorController.activePane'

  isRoot: (->
    App.get('router.ideEditorController.rootPane') == this
  ).property 'App.router.ideEditorController.rootPane'

  isSplit: (->
    @get('left')? && @get('right')? && !@get('tabs')?
  ).property 'left', 'right', 'tabs'

  tabDidChange: (->
    TabWatcher.notifyOfChange()
  ).observes 'tabs.@each'

  discard: ->
    @setProperties
      tabs: null
      left: null
      right: null
      parent: null

  split: (horizontal=false) ->
    return if @get 'isSplit'
    tabs = @get 'tabs'
    @setProperties
      tabs: null
      left: leftPane = App.EditorPane.create(tabs: tabs, parent: this)
      right: App.EditorPane.create(tabs: Em.A(), parent: this)
      horizontal: horizontal

    if @get 'active'
      leftPane.makeActive()

  makeActive: ->
    # if pane is split, recursively find unsplit pane to make active
    if @get('isSplit')
      left = @get 'left'
      right = @get 'right'
      (left || right)?.makeActive()
    else
      App.set 'router.ideEditorController.activePane', this

  findBy: (key, value) ->
    # recursive findBy
    if @get('isSplit')
      left = @get 'left'
      right = @get 'right'
      left?.findBy(key, value) || right?.findBy(key, value)
    else
      @_super(key, value)

  allTabs: ->
    col = []
    if (t = @get 'tabs')
      col.push.apply col, @get 'tabs'
    if (l = @get('left')?.allTabs())
      col.push.apply col, l
    if (r = @get('right')?.allTabs())
      col.push.apply col, r
    col

  close: ->
    return if @get('isSplit') || !@get('parent')
    parent = @get 'parent'
    active = @get 'active'

    # discard this pane
    if @get('length') > 0
      @removeAt(0, @get('length'))
    @discard()

    siblingPane = parent.get(if parent.get('right') == this
      'left'
    else
      'right')

    # copy sibling pane's data over to parent (unsplit)
    leftOfSibling = siblingPane.get('left')
    rightOfSibling = siblingPane.get('right')
    parent.setProperties
      tabs: siblingPane.get 'tabs'
      left: leftOfSibling
      right: rightOfSibling
      horizontal: siblingPane.get 'horizontal'
    leftOfSibling?.set 'parent', parent
    rightOfSibling?.set 'parent', parent
    siblingPane.discard()

    # make parent pane active if either sibling or this is active
    if active || siblingPane.get 'active'
      parent.makeActive()
