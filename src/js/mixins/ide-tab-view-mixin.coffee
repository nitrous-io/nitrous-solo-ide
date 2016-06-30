App.IdeTabViewMixin = Em.Mixin.create
  actions:
    didClickTab: (tab) ->
      @get('controller').makeTabActive tab
      false

    didClickClose: (tab) ->
      @get('controller').removeTab tab
      false

    didClickNew: ->
      @get('controller').createTab()
      false
