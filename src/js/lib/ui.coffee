$ = window.jQuery

window.ui =

  clearDropdowns: (options) ->
    $('body').off 'click.ui-dropdown-bg'
    $dropdowns = $('.ui.dropdown')
    if options?.except?
      $dropdowns = $dropdowns.not(options.except)
    $dropdowns.each (i, el) ->
      $el = $(el).removeClass('open')
      $menu = $el.find('> ul.dropdown-menu')
      $menu.data('timeout', window.setTimeout(->
        $menu.hide()
      ,200))

  openDropdown: (evt, $dropdown, trigger) ->
    if $dropdown.hasClass('open') && trigger != "mouseover"
      ui.clearDropdowns()
    else
      ui.clearDropdowns(except: $dropdown)
      $menu = $dropdown.find('> ul.dropdown-menu').show()
      window.clearTimeout($menu.data('timeout'))
      $dropdown.addClass('open')

      # Close menu when console is clicked/on focus.
      window.onblur = =>
        ui.clearDropdowns()

      $('body').one 'click.ui-dropdown-bg', (e) ->
        if $(e.target).closest('.dropdown').length == 0
          ui.clearDropdowns()
          false
    evt?.stopPropagation()
    evt?.preventDefault()

  handleDropdowns: ->
    $('body').on 'click.ui-dropdown-menuitem', '.ui.dropdown ul.dropdown-menu > li a', (evt) ->
      ui.clearDropdowns()
      evt.stopPropagation()
      href = $(this).attr('href')
      if !href || href == '#'
        evt.preventDefault()

    $('body').on 'click.ui-dropdown', '.ui.dropdown', (evt) ->
      ui.openDropdown(evt, $(this))

    $('body').on 'mouseover.ui-dropdown', '.primary-nav .ui.dropdown', (evt) ->
      $('.primary-nav .ui.dropdown').each (i, el) =>
        if $(el).hasClass('open')
          ui.openDropdown(evt, $(this), "mouseover")

  showModal: ($modal, cb) ->
    if !($modal instanceof jQuery)
      $modal = $($modal)
    $modal.addClass('flex')
    $modal.removeClass('hide')
    $modal.find('.focus').focus()
    window.setTimeout(->
      $modal.addClass('show')
      cb?()
    , 50)

  hideModal: ($modal, cb) ->
    if !($modal instanceof jQuery)
      $modal = $($modal)
    $modal.removeClass('show')
    window.setTimeout(->
      $modal.addClass('hide')
      $modal.removeClass('flex')
      cb?()
    , 151)

$ ->
  ui.handleDropdowns()
