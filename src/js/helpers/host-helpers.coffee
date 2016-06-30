Em.Handlebars.helper 'region-slug', (regionId) ->
  index = App.get('regionIndex')
  return index[regionId]?.get('slug')

Em.Handlebars.helper 'plan-slug', (planId) ->
  index = App.get('planIndex')
  return index[planId]?.get('slug')
