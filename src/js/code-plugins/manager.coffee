window.App ||= {}

App.CodePluginsManager =
  klasses: {}
  aliases: {}

  globalPlugins: {}

  # track all plugins so we can perform updates
  # on key variables (opSocket etc)
  # maps pluginType objects to plugin instances
  activePlugins: {}
  # maps pluginType to global plugin instances
  activeGlobalPlugins: {}

  availableOptions: {}

  setAvailableOption: (optName, value)->
    @availableOptions[optName] = value

    for type, plugin of @activePlugins
      plugin.setOption(optName, value)

    for type, plugin of @activeGlobalPlugins
      plugin.setOption(optName, value)

  registerCodePlugin: (type, klass, aliases = [])->
    klass.pluginType = type
    @klasses[type] = klass
    for alias in aliases
      @aliases[alias] = type

  registerGlobalPlugin: (type, klass)->
    @globalPlugins[type] = klass

  forType: (type)->
    @klasses[type] || @klasses[@aliases[type]]

  initPluginForType: (doc, mode)->
    if plType = @forType(mode)
      if plType.beta
        return null unless @availableOptions.userSettings?.beta

      pl = new plType(doc)
      @setOptions(pl)
      pl.pluginType = plType.pluginType

      @activePlugins[pl.pluginType] ||= []
      @activePlugins[pl.pluginType].push pl

      if gblType = @globalPlugins[plType.pluginType]
        unless @activeGlobalPlugins[plType.pluginType]
          gblPlugin = new gblType()
          @setOptions(gblPlugin)

          @activeGlobalPlugins[plType.pluginType] = gblPlugin

      pl.globalPlugin = @activeGlobalPlugins[plType.pluginType]

      pl.globalPlugin?.afterInitialize()
      pl.afterInitialize()
      return pl

    null

  pluginClosed: (plugin)->
    return unless @activePlugins[plugin.pluginType]
    if (indx = @activePlugins[plugin.pluginType].indexOf(plugin)) != null
      @activePlugins[plugin.pluginType].splice(indx, 1)

      if @activePlugins[plugin.pluginType].length == 0
        gbl = @activeGlobalPlugins[plugin.pluginType]
        if gbl
          gbl.unload()
          @activeGlobalPlugins[plugin.pluginType] = null


  setOptions: (pluginInstance)->
    for opt, value of @availableOptions
      pluginInstance.setOption(opt, value)