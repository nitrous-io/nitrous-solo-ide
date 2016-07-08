keysToSubmit = [
  'auto_close_brackets'
  'highlight_line'
  'keybindings'
  'match_brackets'
  'remove_trailing_whitespace_on_save'
  'ruler_column'
  'show_line_numbers'
  'show_trailing_space'
  'soft_tabs'
  'tab_size'
  'theme'
  'wrap_lines'
  'font_size'
]

App.UserSettings = klass = Em.Object.extend

  requestSave: (delay = 5000)->
    return if @saveTimer

    @saveRequested = true
    @saveTimer = window.setTimeout(=>
      @saveTimer = null
      @save()
      @saveRequested = false
    , delay)

  save: ->
    return unless @saveRequested
    Em.$.ajax(
      type: 'POST',
      url: '/api/v0/user/settings',
      contentType : "application/json",
      dataType: "json",
      headers: { Authorization: "Bearer #{App.get 'token'}" },
      data: JSON.stringify(@getProperties(keysToSubmit))
    ).done((data, status, jqxhr) =>
      @setProperties(data.user_settings)
    ).fail (jqxhr) =>
      @requestSave(1000)


klass.reopenClass
  fetch: ->
    new Ember.RSVP.Promise (resolve, reject) =>
      resolve(App.UserSettings.create(
        FakeJSON.user_settings
      ))
