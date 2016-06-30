App.FeedbackController = Em.Controller.extend
  subject: null
  message: null
  sending: false
  closeFeedback: false
  titleOverride: null
  onSuccessMessage: null

  clear: ->
    @setProperties
      subject: null
      message: null
      sending: false
      closeFeedback: false
      titleOverride: null
      onSuccessMessage: null

  title: (->   
    if t = @get 'titleOverride'   
      return t    
    'Send Feedback'   
  ).property 'titleOverride'    

  actions:
    send: ->
      @set 'sending', true

      data =
        subject: @get 'subject'
        body: @get 'message'
        userAgent: navigator.userAgent 
        platform: navigator.platform
        currentURL: window.location.href 

      Em.$.ajax(
        type: 'POST',
        url: '/api/v0/feedback',
        headers: { Authorization: "Bearer #{App.get 'token'}" },
        data: data
      ).done((data, status, jqxhr) =>
        msg = @get('onSuccessMessage') || "Your feedback was successfully sent!"
        App.snackbar.post(msg)
        @clear()
        @set 'closeFeedback', true
      ).fail (jqxhr) =>
        App.postError(jqxhr.responseJSON, "Failed to send feedback!")
        @set 'sending', false
