Em.Handlebars.helper 'truncate', (text, limit) ->
  _limit = limit || 50
  if text.length > limit
    return text.substr(0, limit) + '…'
  text

Em.Handlebars.helper 'plural', (value, singular, plural) ->
  if value == 1
    return singular
  return plural