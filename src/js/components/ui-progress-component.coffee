App.UiProgressComponent = Em.Component.extend
  classNames: ['ui', 'progress']
  classNameBindings: ['hide']
  attributeBindings: ['value:data-value', 'max:data-max']

  value: 0
  max: 0
  indeterminate: false

  cssWidth: (->
    value = @get('value') || 0
    max = @get('max') || 0
    if value >= 0 && max > 0
      "width: #{value / max * 100}%"
  ).property 'value', 'max'
