App.UiConnectivityIndicatorComponent = Em.Component.extend
  classNames: ['ui', 'modal', 'ui-connectivity-indicator']
  showBinding: 'App.offline'

  html: '<i class="fa fa-chain-broken"></i> Your Internet connection appears to be down.'

  showDidChange: (->
    if @get 'show'
      ui.showModal(@$())
    else
      ui.hideModal(@$())
  ).observes 'show'
