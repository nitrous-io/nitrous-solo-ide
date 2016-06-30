Ember.Handlebars.helper 'formatMatchedLine', (line) ->
  escaped = Handlebars.Utils.escapeExpression(line)
  delimStart = "\\\x1b\\[30;43m"
  delimEnd = "\\\x1b\\[0m\\\x1b\\[K"
  re = new RegExp("#{delimStart}(.+?)#{delimEnd}", 'g')
  formatted = escaped.replace(re, '<span class="search-match">$1</span>')
  new Ember.Handlebars.SafeString(formatted)

# Renders search results with no whitespace between them (due to white-space: pre-wrap)
# TODO this can go back into template once Handlebars whitespace control is working
# https://github.com/emberjs/ember.js/issues/4305
#
# Result looks like
# <span class="line-text">
#   {{each line.lineParts }}
#     {{if match }}
#     <span class="search-match">{{ text }}</span>
#     {{else}}
#     <span>{{ text }}</span>
#     {{/if}}
#   {{/each}}
# </span>
Ember.Handlebars.helper 'searchResultLine', (line) ->
  parts = _.map line.lineParts, (part) ->
    classAttr = if part.match then 'class="search-match"' else ''
    [
      '<span ', classAttr, '>'
      Handlebars.Utils.escapeExpression(part.text)
      '</span>'
    ].join('')
  new Ember.Handlebars.SafeString('<span class="line-text">' + parts.join('') + '</span>')
