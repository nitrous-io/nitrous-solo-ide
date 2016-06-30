App.Repository = klass = Em.Object.extend
  name: null
  git_url: null
  private: false

klass.reopenClass
  url: '/github/repos'
  collectionKey: 'repos'
