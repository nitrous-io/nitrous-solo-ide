App.util =
  IsMac:
    navigator.userAgent.indexOf("Macintosh") != -1

  IsMobile:
    navigator.userAgent.match(/(Android|iPad|iPhone)/) != null

  # Algo stolen from http://ejohn.org/files/pretty.js
  humanizedTimeProperty: (property) ->
    return (->
      val = @get(property)
      # Assume property is in UTC
      val = if _.isDate(val) then val.toISOString() else val
      date = new Date((val || "").replace(/-/g,"/").replace(/[TZ]/g," "))
      # Get now in UTC as well
      now = new Date(new Date().toISOString().replace(/-/g,"/").replace(/[TZ]/g," "))

      diff = (now.getTime() - date.getTime()) / 1000
      day_diff = Math.floor(diff / 86400)

      if isNaN(day_diff) || day_diff < 0
        return

      day_diff == 0 && (
                diff < 60 && "just now" ||
                diff < 120 && "a minute ago" ||
                diff < 3600 && Math.floor( diff / 60 ) + " minutes ago" ||
                diff < 7200 && "an hour ago" ||
                diff < 86400 && Math.floor( diff / 3600 ) + " hours ago") ||
                day_diff == 1 && "yesterday" ||
                day_diff < 7 && day_diff + " days ago" ||
                day_diff < 31 && Math.ceil( day_diff / 7 ) + " weeks ago" ||
                day_diff < 365 && Math.floor( day_diff / 30 ) + " months ago" ||
                day_diff < 730 && "last year" ||
                Math.floor( day_diff / 365 ) + " years ago"
    ).property(property)

  strftime: (format, date) ->
    strftime(format, date)

  randomElement: (array) ->
    array[Math.floor(Math.random() * array.length)]

  autolink: (text) ->
    urlPattern = ///
      (^|\s)                                # Capture the beginning of string or leading whitespace
      (
        (?:https?|ftp)://                   # Look for a valid URL protocol (non-captured)
        [\-A-Z0-9+\u0026@#/%?=()~_|!:,.;]*  # Valid URL characters (any number of times)
        [\-A-Z0-9+\u0026@#/%=~()_|]         # String must end in a valid URL character
      )
    ///gi

    Handlebars.Utils.escapeExpression(text)
                    .replace( urlPattern, (match, space, url) ->
                      link = "<a href='#{url}' target='_blank'>#{url}</a>"
                      "#{space}#{link}"
                    ).htmlSafe()

  pluralize: (count, singularForm, pluralForm) ->
    term = if count == 1 then singularForm else pluralForm
    [count, term].join(' ')

  connectionError: ->
    App.set 'flashMessage', type: 'error', text: 'Error connecting to server.  Please contact support@nitrous.io'
