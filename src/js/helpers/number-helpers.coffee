Em.Handlebars.helper 'mebibytes', (num) ->
  if typeof num == 'number'
    (num / (1024*1024)).toFixed(2)

Em.Handlebars.helper 'gibibytes', (num) ->
  if typeof num == 'number'
    (num / (1024*1024*1024)).toFixed(2)

Em.Handlebars.helper 'toFixed', (num, digits) ->
  if typeof num == 'number'
    num.toFixed(digits)

Em.Handlebars.helper 'currency', (num) ->
  if typeof num == 'number'
    num.toFixed(2)

Em.Handlebars.helper 'decimal', (num, digits) ->
  if typeof num == 'number'
    num / Math.pow(10, digits)
