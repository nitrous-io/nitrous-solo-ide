App.FeedbackView = Em.View.extend
  elementId: 'feedback-view'
  templateName: 'shared/feedback'

  closeFeedbackDidChange: (->
    if @get 'controller.closeFeedback'
      @set 'controller.closeFeedback', false
      @send 'cancelFeedback'
  ).observes 'controller.closeFeedback'

  didInsertElement: ->
    @_super()
    App.on 'open-feedback-dialog', (title, success)=>
      @set 'controller.titleOverride', title
      @set 'controller.onSuccessMessage', success
      ui.showModal(@$('#feedback-dialog'))
      @$('#feedback-subject').focus()

  willDestroyElement: ->
    @_super()
    App.off 'open-feedback-dialog'

  actions:
    cancelFeedback: ->
      ui.hideModal(@$('#feedback-dialog'))
