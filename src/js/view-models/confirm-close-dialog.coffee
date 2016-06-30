App.ConfirmCloseDialog = Em.Object.extend
  document: null

  saveButtonTitle: (->
    if @get 'document.path'
      'Save'
    else
      'Save...'
  ).property 'document.path'
