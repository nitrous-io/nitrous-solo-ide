App.IdePathNameView = Em.View.extend
  templateName: 'path-name'
  tagName: 'a'
  attributeBindings: ['href']
  classNameBindings: ['path.loading:loading', 'path.beingDeleted:deleted']

  href: '#'
  path: null
