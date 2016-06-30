App.TerminalConnectionMixin = Ember.Mixin.create
  makeUrl: (container, terminal, action) ->
    new Ember.RSVP.Promise (resolve, reject) ->
      reject(null) unless container

      term = terminal.term
      cid = container.get 'cid'
      freighterdUrl = container.get 'freighterdUrl'

      if ['shell', 'attach', 'logs'].indexOf(action) == -1
        action = 'shell'

      container.requestToken([action]).then (token) ->
        token = encodeURIComponent(token.token)

        protocol = location.protocol.replace('http', 'ws')
        url = "#{protocol}//#{freighterdUrl}/containers/#{cid}/#{action}?token=#{token}&width=#{term.cols}&height=#{term.rows}"

        switch action
          when 'shell'
            command = encodeURIComponent(getLoginCommand(container.get 'loginUsername'))
            terminal.binaryMode = true
            url += "&binary=true&command=#{command}"
          when 'logs'
            url += "&follow=true"
            terminal.readonly = true
            term.convertEol = true
          when 'attach'
            term.convertEol = true

        resolve(url)
      , (jqxhr) ->
        reject(jqxhr)

getLoginCommand = (username) ->
  username ||= "root"
  loginCmd = "/bin/login -f #{username} -p TERM=xterm-256color"
  "script -q -c '#{loginCmd}' /dev/null || #{loginCmd}"
