PREVIEW_PORT_START = 1024
SUPPORTED_SYSTEM_PORTS = [80]

App.Container = klass = Em.Object.extend
  id: null
  cid: null
  user_id: null
  host_id: null
  slug: null
  name: null
  state: null
  preview_hostname: null

  config: null
  host: null

  metadata: null
  user_data: null

  env: (->
    # Config will not be set if host is not running. Get env only if config is valid.
    transformEnvArrayToHash @get('config')?.env
  ).property 'config'

  loginUsername: (->
    u = @get('env')["NITROUS_USERNAME"] || @get('user')
    if u == ""
      return "root"
    u
  ).property 'env'

  userData: (->
    hsh = @get 'user_data'
    return unless hsh
    data = {}
    for key of hsh
      data[key] = JSON.parse(hsh[key])
    data
  ).property 'user_data'

  previewPort: (->
    p = @get('env')["NITROUS_PREVIEW_PORT"]
    if p
      parseInt(p)
    else
      null
  ).property 'env'

  freighterdUrl: (->
    hostname = @get('host')?.proxy_hostname
    port = @get('host')?.freighterd_port
    if hostname
      if port && port != 65333
        return "#{hostname}:#{port}"
      hostname
  ).property 'host'

  homePath: (->
    username = @get 'loginUsername'
    if username == "root"
      "/"
    else
      "/home/#{username}"
  ).property 'loginUsername'

  rootPath: (->
    @get('metadata.rootPath') || @get('env.NITROUS_FILETREE_ROOT') || @get('homePath')
  ).property 'homePath', 'env.NITROUS_FILETREE_ROOT ', 'metadata.rootPath'

  previewablePorts: (->
    publicPorts = Em.A()
    previewPort = @get('previewPort')

    return publicPorts unless @get('config.port')
    for port in @get('config.port')
      regex = ///
        ^public:  # should be a public port binding
        (\d*):    # host port
        (\d*)     # container port
        (\/tcp)?  # can be followed by tcp
        $         # end of string
      ///
      if m = port.match(regex)
        hostPort = m[1]
        containerPort = parseInt(m[2])
        if @validPreviewPort(containerPort)
          publicPorts.push { port: port, hostPort: hostPort, containerPort: containerPort, preview: containerPort == @get('previewPort') }
    publicPorts.sortBy('containerPort')
  ).property 'config', 'config.port.@each'

  scripts: (->
    scripts = @get('config.scripts')
    return scripts if !scripts

    newScripts = {}

    # Convert known keys to English.
    keys = Object.keys(scripts)
    keys = keys.sort()
    keys.forEach (k) ->
      switch k
        when 'start'
          # Ignore it. This is run whenever the container is started and should
          # not appear.
          ;
        when 'post-create'
          # Ignore it. This is run whenever the container is created by Quickstart
          # and should not appear.
          ;
        else
          newScripts[k] = scripts[k]

    newScripts
  ).property 'config', 'config.scripts'

  validPreviewPort: (port) ->
    port == 80 || port >= 1024

  requestToken: (permissions) ->
    promise = new Em.RSVP.Promise (resolve, reject) =>
      Em.$.ajax(
        type: 'POST',
        url: "/api/v0/containers/#{@get 'slug'}/token",
        headers: { Authorization: "Bearer #{App.get 'token'}" }
        data: {
          permission: permissions
        }
      ).done((data, status, jqxhr) ->
        resolve(data)
      ).fail (jqxhr) ->
        reject(jqxhr)
    promise

  loadCollaborators: ->
    App.ContainerCollaborator.fetch(@get 'id').then (collabs)=>
      @set 'collaborators', collabs

  loadHost: ->
    new Em.RSVP.Promise (resolve, reject) =>
      Em.$.ajax(
        type: 'GET',
        url: "/api/v0/hosts/#{@get 'host_id'}",
        headers: { Authorization: "Bearer #{App.get 'token'}" }
      ).done((data, status, jqxhr) =>
        @set 'host', data.host
        resolve(data)
      ).fail (jqxhr) ->
        reject(jqxhr)

  setMetadata: (data)->
    new Em.RSVP.Promise (resolve, reject) =>
      Em.$.ajax(
        type: 'PUT',
        url: "/api/v0/containers/#{@get 'slug'}/metadata",
        headers: { Authorization: "Bearer #{App.get 'token'}" },
        data: data
      ).done((retData, status, jqxhr) =>
        Object.keys(data).forEach (k) =>
          @set("metadata.#{k}", data[k])
        resolve(retData)
      ).fail (jqxhr) ->
        reject(jqxhr)

  setUserData: (key, value)->
    new Em.RSVP.Promise (resolve, reject) =>
      Em.$.ajax(
        type: 'PUT',
        url: "/api/v0/containers/#{@get 'slug'}/user_data",
        headers: { Authorization: "Bearer #{App.get 'token'}" },
        data:
          key: key
          value: JSON.stringify(value)
      ).done((retData, status, jqxhr) =>
        resolve(retData)
      ).fail (jqxhr) ->
        reject(jqxhr)

klass.reopenClass
  fetch: (slug) ->
    promise = new Em.RSVP.Promise (resolve, reject) =>
      Em.$.ajax(
        type: 'GET',
        url: "/api/v0/containers/#{slug}",
        headers: { Authorization: "Bearer #{App.get 'token'}" }
      ).done((data, status, jqxhr) ->
        container = App.Container.create(data.container)
        resolve(container)
      ).fail (jqxhr) ->
        reject(jqxhr)
    promise

transformEnvArrayToHash = (envVars) ->
  hash = {}
  return hash unless envVars
  for v in envVars
    m = v.match /^([^=]+)=(.*)$/
    key = m[1]
    val = m[2]
    hash[key] = val
  hash
