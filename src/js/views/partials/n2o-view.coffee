App.N2OView = Em.View.extend
  templateName: 'templates/partials/n2o'
  classNames: ['n2o_view']

  freeN2OBinding: Em.Binding.oneWay 'App.user.free_n2o'
  maxN2OBinding: Em.Binding.oneWay 'App.user.max_n2o'

  barWidthStyle: (->
    freeN2O = @get('freeN2O') ? 0
    maxN2O  = @get('maxN2O')  ? 0
    "width: #{freeN2O / maxN2O * 100}%"
  ).property 'freeN2O', 'maxN2O'

  click: ->
    App.get('router').transitionTo 'n2o.bonus'
