App.User = klass = Em.Object.extend
  id: null
  username: null
  name: null
  email: null
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

klass.reopenClass
  fetch: ->
    new Ember.RSVP.Promise (resolve, reject) =>
      resolve(App.User.create(
        FakeJSON.user
      ))
