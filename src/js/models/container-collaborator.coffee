App.ContainerCollaborator = klass = Em.Object.extend
  id: null
  user_id: null
  username: null
  gravatar_hash: null
  name: null

  gravatar: (->
    "https://secure.gravatar.com/avatar/#{@get('gravatar_hash')}?default=retro&secure=true&size=72"
  ).property 'gravatar_hash'

  isSelf: (->
    userId = App.get 'user.id'
    if userId == @get('user_id')
      true
  ).property 'App.user.id'

klass.reopenClass
  fetch: (cId) ->
    new Em.RSVP.Promise (resolve, reject) =>
      Em.$.ajax(
        type: 'GET',
        url: "/api/v0/containers/#{cId}/collaborators",
        headers: { Authorization: "Bearer #{App.get 'token'}" }
      ).done((data, status, jqxhr) ->
        store = for collab in data.collaborators
          App.ContainerCollaborator.create collab
        resolve(store)
      ).fail (jqxhr) ->
        reject(jqxhr)

