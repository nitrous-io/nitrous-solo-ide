App.IdeIframeView = Em.View.extend
  templateName: 'ide/iframe'
  classNames: ['ide-iframe-view']
  classNameBindings: ['document.active']

  uri: (->
    @get 'document.content'
  ).property 'document.content', 'document.contentType'

  readmeBinding: 'document.readme'
