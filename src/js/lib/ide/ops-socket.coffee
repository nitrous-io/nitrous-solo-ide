require './evented-socket'

App.OpsSocket = klass = App.EventedSocket.extend
  action: 'ops'
  binary: true

  unwatchDir: (absolutePath) ->
    @send 'fs', 'unwatchDir', absolutePath

  unwatchFile: (absolutePath) ->
    @send 'fs', 'unwatchFile', absolutePath

  fetchFileList: (absolutePath, callback) ->
    @send 'fs', 'list', absolutePath, callback

  fetchFileContent: (absolutePath, callback) ->
    @send 'fs', 'read', absolutePath, callback

  downloadFile: (absolutePath, callback) ->
    @send 'fs', 'download', absolutePath, callback

  writeFile: (absolutePath, content, callback) ->
    @send 'fs', 'write', absolutePath, content, callback

  writeNewFile: (absolutePath, content, callback) ->
    @send 'fs', 'writeNew', absolutePath, content, callback

  makeDirectory: (absolutePath, callback) ->
    @send 'fs', 'makeDir', absolutePath, callback

  sendUploadToken: (absolutePath, token, callback) ->
    @send 'fs', 'upload', absolutePath, token, callback

  deleteFile: (absolutePath, callback) ->
    @send 'fs', 'deleteFile', absolutePath, callback

  deleteDir: (absolutePath, callback) ->
    @send 'fs', 'deleteDir', absolutePath, callback

  rename: (currentPath, newPath, callback) ->
    @send 'fs', 'rename', currentPath, newPath, callback

  fileFind: (term, root, callback) ->
    @send 'finder', 'file_find', term, root, callback

  # cmd : command to execute as a list e.g. ["ls"], ["ls", "-lah"]
  # cwd : current working directory e.g. "/home". empty strings means whatever
  #       is current in cops process
  # env : additional env variables as a list e.g. ["FOO=bar", "SECOND=two"].
  #       empty list means no additions
  # callback is: (err, cmdErrMsg, cmdStdout, cmdStderr)
  # Note: the command is run with shell, which includes things like substitution
  # of shell variables e.g. command ["echo", "$PATH"] will print PATH env variable
  run: (cmd, cwd, env, callback) ->
    @send 'cmd', 'run', cmd, cwd, env, callback

  search: (id, term, location, ignoreCase, useRegexp, filePattern, callback) ->
    request =
      id: id
      term: term
      root: location
      ignore_case: ignoreCase
      use_regexp: useRegexp
      file_pattern: filePattern
    @send 'finder', 'search', request, callback
