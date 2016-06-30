Em.Handlebars.helper 'durationInWords', (duration) ->
  if typeof duration == 'number'
    days = parseInt(duration / (60*60*24), 10)
    hours = parseInt(duration / (60*60), 10) % 24
    minutes = parseInt(duration / 60, 10) % 60
    seconds = Math.floor(duration % 60)
    components = []
    if days > 0
      components.push "#{days}d"
    if hours > 0 || days > 0
      components.push "#{hours}h"
    if minutes > 0 || days > 0 || hours > 0
      components.push "#{minutes}m"
    if seconds > 0 || minutes > 0 || days > 0 || hours > 0
      components.push "#{seconds}s"
    return "0s" if components.length == 0
    components.join(' ')
