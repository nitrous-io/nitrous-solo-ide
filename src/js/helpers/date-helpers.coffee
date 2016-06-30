monthNames = [
  "January"
  "February"
  "March"
  "April"
  "May"
  "June"
  "July"
  "August"
  "September"
  "October"
  "November"
  "December"
]

Em.Handlebars.helper 'ago', (date) ->
  if date instanceof Date
    $.timeago(date)

Em.Handlebars.helper 'utc', (date) ->
  if date instanceof Date
    date.toUTCString()

Em.Handlebars.helper 'monDayYear', (date) ->
  if date instanceof Date
    month = monthNames[date.getMonth()].slice(0, 3)
    "#{month} #{date.getDate()}, #{date.getFullYear()}"

Em.Handlebars.helper 'simpledate', (date) ->
  if date instanceof Date
    month = monthNames[date.getMonth()]
    "#{month} #{date.getDate()}, #{date.getFullYear()}"

Em.Handlebars.helper 'daymonth', (date) ->
  if date instanceof Date
    mnt = date.getMonth()
    mName = monthNames[mnt]
    "#{date.getDate()} #{mName}"

Em.Handlebars.helper 'monthyear', (date) ->
  if date instanceof Date
    mnt = date.getMonth()
    mName = monthNames[mnt]
    "#{mName} #{date.getFullYear()}"

Em.Handlebars.helper 'basicdate', (date) ->
  unless date instanceof Date
    return
  yr = date.getFullYear()
  mnt = (date.getMonth() + 1)
  day = (date.getDate())
  hr = date.getHours()
  if hr == 0
    hr = 12
  min = date.getMinutes()

  "#{yr}-#{util.padZeroes(mnt)}-#{util.padZeroes(day)}"

Em.Handlebars.helper 'basicdatetime', (date) ->
  unless date instanceof Date
    return
  yr = date.getFullYear()
  mnt = (date.getMonth() + 1)
  day = (date.getDate())
  hr = date.getHours()
  if hr == 0
    hr = 12
  min = date.getMinutes()

  "#{yr}/#{util.padZeroes(mnt)}/#{util.padZeroes(day)} #{util.padZeroes(hr)}:#{util.padZeroes(min)}"

Em.Handlebars.helper 'dateabbr', (date) ->
  if date instanceof Date
    new Ember.Handlebars.SafeString(Em.$('<abbr>').attr('title', date.toString()).text($.timeago(date))[0].outerHTML)
