App.User = klass = Em.Object.extend
  id: null
  username: null
  name: null
  email: null
  admin: null
  created_at: null
  updated_at: null

  init: ->
    @_super.apply this, arguments

  gravatar: (->
    "https://secure.gravatar.com/avatar/#{md5(@get 'email')}?default=retro&secure=true&size=48"
  ).property 'email'

  free: (->
    @get('billing_profile.state') == "free"
  ).property 'billing_profile.state'

  usageRemainingHours: (->
    Math.round(@get('usage_remaining') / (60*60))
  ).property 'usage_remaining'

klass.reopenClass
  fetch: ->
    new Ember.RSVP.Promise (resolve, reject) =>
      Em.$.ajax(
        type: 'GET',
        url: '/api/v0/user',
        headers: { Authorization: "Bearer #{App.get 'token'}" }
      ).done((data, status, jqxhr) ->
        resolve(App.User.create(data.user))
      ).fail (jqxhr) ->
        reject(jqxhr)
