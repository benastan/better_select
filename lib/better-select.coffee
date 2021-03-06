###############
# DOM Helpers #
###############

$$ = (html) ->
  elm = document.createElement 'div'
  elm.innerHTML = html
  if elm.children.length > 1 then elm.children else elm.children[0]

getClasses = (tgt) -> tgt.getAttribute('class').split ' '

setClasses = (tgt, classes) ->
  tgt.setAttribute 'class', classes.join ' '
  tgt

addClass = (tgt, className) ->
  classes.push(className) if (classes = getClasses tgt).indexOf(className) is -1
  setClasses tgt, classes

removeClass = (tgt, className) ->
  classes.splice(index, 1) unless (index = (classes = getClasses tgt).indexOf className) is -1
  setClasses tgt, classes

findForm = (tgt) ->
  parent = tgt.parentNode
  return false unless parent
  return parent if parent.tagName is 'FORM'
  return findForm parent

contains = (ancestor, tgt) -> return true if tgt == ancestor while tgt = tgt.parentNode

###################
# Browser Helpers #
###################

chrome = /AppleWebKit\/(.+)Chrome/.test navigator.userAgent
moz = /Gecko\//.test navigator.userAgent

###############
# CSS Helpers #
###############

getCSSValue = (tgt, value) -> window.getComputedStyle(tgt).getPropertyValue(value)

#######################
# Positioning Helpers #
#######################

getPositioning = (tgt) -> window.getComputedStyle(tgt).getPropertyValue('position')
pageOffset = ->
  doc = document.body
  offset = 
    top: ( window.pageYOffset || doc.scrollTop )  - ( doc.clientTop  || 0 )
    left: ( window.pageXOffset || doc.scrollLeft ) - ( doc.clientLeft || 0 )

getPos = (tgt) ->
  position = getPositioning(tgt)
  if contains(doc = document.body, tgt)
    bcr = tgt.getBoundingClientRect()
    box =
      top: bcr.top  + (if position is 'fixed' then 0 else ( window.pageYOffset || doc.scrollTop )  - ( doc.clientTop  || 0 ))
      left: bcr.left + (if position is 'fixed' then 0 else ( window.pageXOffset || doc.scrollLeft ) - ( doc.clientLeft || 0 ))

getTop = (tgt) -> getPos(tgt).top
getLeft = (tgt) -> getPos(tgt).left

#############
# Constants #
#############

LETTERS = 'a b c d e f g h i j k l m n o p q r s t u v w x y z'.split ' '
NUMBERS = '0 1 2 3 4 5 6 7 8 9 0'.split ' '

########################
# BetterSelect Helpers #
########################

build_element = (what, orig, obj) ->
  ((elm = $$ _.template(obj["#{what}_template"]) obj["process_#{what}"] orig).orig = orig).better_version = elm
  elm.better_select = obj
  elm

renderOption = (orig_option, bs) ->
  option = build_element 'option', orig_option, bs

  option.reset = ->
    @orig.selected = undefined
    @setAttribute 'class', 'option'
    bs.reset @

  option.select = ->
    @orig.selected = 'selected'
    @setAttribute 'class', 'option selected'
    bs.set_selected option
    bs.toggle() if bs.open

  option.scroll_by = ->
    if option.offsetTop < bs.dropdown.scrollTop
      bs.dropdown.scrollTop = option.offsetTop
    if option.offsetTop + option.offsetHeight > bs.dropdown.offsetHeight - bs.dropdown.scrollTop
      bs.dropdown.scrollTop = option.offsetTop + option.offsetHeight - bs.dropdown.offsetHeight

  option.focus = -> bs.set_focused option

  option.addEventListener 'click', -> option.select()
  option.addEventListener 'mouseover', -> option.focus()

  orig_option.better_option = option
  option.orig_option = orig_option
  bs.options.push option
  first_char = option.innerHTML.substr(0, 1).toLowerCase()
  chars = option.innerHTML.toLowerCase().split ''
  i = 0
  ii = chars.length
  option_thus_far = ''
  for char in chars
    option_thus_far = "#{option_thus_far}#{char}"
    unless bs.options_by_char[option_thus_far]
      bs.options_by_char[option_thus_far] = []
      bs.options_by_char[option_thus_far].sort = ->
        (sorted = _(@).sortBy 'innerHTML').unshift 0, @.length
        @.splice.apply @, sorted
    bs.options_by_char[option_thus_far].push option
    bs.options_by_char[option_thus_far].sort()
  option

renderOptionGroup = (orig_group, bs) ->
  group = build_element 'option_group', orig_group, bs
  group.appendChild(renderOption child, bs) for child in orig_group.children
  bs.option_groups.push group
  group

######################
# BetterSelect Class #
######################

class BetterSelect
  defaults:
    positionDropdown: true
    resizeDropdown: true

  constructor: (elm, options) ->
    return unless elm && elm.tagName && elm.tagName is 'SELECT'
    @form = findForm elm
    @settings = _.extend {}, @defaults, options
    @options = []
    @options_by_char = {}
    @option_groups = []
    selected = elm.selectedOptions
    @select = build_element 'select', elm, @
    [@selected_option, @dropdown] = @select.children
    @selected_option.better_select = @
    elm.better_select = @

    if elm.id
      @select.id = "#{elm.id}-better-select"
      @dropdown.id = "#{elm.id}-better-select-dropdown"

    @default_selected = [elm.children[elm.selectedIndex]]
    elm.parentNode.insertBefore @select, elm
    elm.parentNode.insertBefore elm, @select
    elm.style.display = 'none'
    children = elm.children

    if @settings.positionDropdown
      document.body.appendChild @dropdown
      @dropdown.style.left = '-9999px'

    for child in children
      switch child.tagName
        when 'OPTION'
          method = renderOption
        when 'OPTGROUP'
          method = renderOptionGroup
      @dropdown.appendChild(method child, @)

    @default_selected[0].better_version.select() if @default_selected

    @selected_option.addEventListener 'click', =>
      if @open
        @focused_option.select() if @focused_option
      else
        @toggle()

    window.addEventListener 'click', (e) =>
      unless e.target == @selected_option || e.target == @select || @options.indexOf(e.target) isnt -1
        @toggle() if @open

    @last_char = false

    event_tgt = @select

    event_tgt.addEventListener 'focus', => addClass @select, 'focus'

    event_tgt.addEventListener 'blur', (e) =>
      if tgt = e.target
        tgt = tgt.parentNode unless tgt.tagName is 'DIV'
        @set_selected tgt unless @options.indexOf(tgt) is -1
      removeClass @select, 'focus'
      document.body.style.overflow = 'auto'
      @toggle() if @open is true
      @keys_pressed = ''
      true

    event_tgt.addEventListener 'keyup', (e) => e.preventDefault() unless [38, 40].indexOf(e.keyCode) is -1

    event_tgt.addEventListener 'keydown', (e) => @process_key_event(e)

    window.addEventListener 'keydown', (e) => @process_key_event(e) if @open

    @select.tabIndex = 0
    @selected_option.tabIndex = -1
    @orig_select = elm

  update: ->
    val = @orig_select.value
    _(@options).each (option) => option.select() if option.orig_option.value is val

  focused_option: false
  focus_index: -1
  select_focused: -> @focused_option.select() if @focused_option

  process_key_event: (e) ->
    keyCode = e.keyCode
    isNumber = keyCode > 47 && keyCode < 58
    isLetter = keyCode > 64 && keyCode < 91

    # Pressed <esc>
    return @toggle() if keyCode is 27

    # Pressed <tab>
    return @select_focused() if keyCode is 9 && @open

    # Continue only if pressed <enter>, <up>, <down>, a letter or a number.
    return unless [13, 38, 40].indexOf(keyCode) isnt -1 || isLetter || isNumber

    # Toggle conditions.
    @toggle() if [38, 40].indexOf(keyCode) isnt -1 && @open is false

    switch keyCode
      # Presed <up>
      when 38
        @options[if (@focus_index -= 1) < 0 then @focus_index = @options.length - 1 else @focus_index].focus()
        @focused_option.scroll_by()

      # Pressed <down>
      when 40
        @options[if (@focus_index += 1) >= @options.length then @focus_index = 0 else @focus_index].focus()
        @focused_option.scroll_by()

      # Pressed <enter>
      when 13
        if @open
          @select_focused()
        else
          e = document.createEvent 'Event'
          e.initEvent 'submit', true, true
          @form.dispatchEvent e

      # Some other key
      else

        if isNumber
          char = NUMBERS[new String(keyCode - 48)]
        else if isLetter
          char = LETTERS[keyCode - 65]

        keys_pressed = _keys_pressed = @keys_pressed = "#{@keys_pressed || ''}#{char}"

        # Reset keys pressed after three seconds.
        _.delay (-> @keys_pressed = '' if _keys_pressed is @keys_pressed ), 3000

        # Make select searchable!
        if char
          while keys_pressed.length
            if @options_by_char[keys_pressed]
              @toggle() unless @open
              @options_by_char[keys_pressed].sort() unless @last_char is char
              option = @options_by_char[keys_pressed].shift()
              @options_by_char[keys_pressed].push option
              option.focus()
              option.scroll_by()
              @focus_index = @options.indexOf option
              keys_pressed = ''
            else
              keys_pressed = (-> k = keys_pressed.split(''); k.shift(); k.join(''))()
          @last_char = char

    e.preventDefault()
    e.stopPropagation()
    e.returnValue = false

  set_focused: (option) ->
    removeClass @focused_option, 'focus' if @focused_option
    addClass @focused_option = option, 'focus'
    @focus_index = @options.indexOf @focused_option

  open: false

  position_dropdown: ->
      @dropdown.style.height = 'auto'
      @dropdown.style['overflow-y'] = 'auto'
      if @dropdown.offsetHeight > window.innerHeight
        height = window.innerHeight * .5
        @dropdown.style.height = height + 'px'
        @dropdown.style['overflow-y'] = 'auto'
        @dropdown_selected_option.scroll_by()
        @adjust_height = true
      index = @options.indexOf(@dropdown_selected_option) 
      if index + 1 == @options.length
        bottom = getTop(@select) + @select.offsetHeight
        selectHeight = @dropdown.offsetHeight
        top = bottom - selectHeight
      else if index == 0
        top = getTop(@select)
      else
        # @dropdown_selected_option.offsetTop returns offset of element from @dropdown.
        top = getTop(@select) - (@dropdown_selected_option.offsetTop - @dropdown.scrollTop)
      pageOffsetTop = pageOffset().top
      top = top - pageOffsetTop

      top = 10 if top < 10
      @dropdown.style.top = top  + 'px'
      @dropdown.style.left = if @open then getLeft(@select) + 'px' else '-9999px'

      dropdown_top = top
      dropdown_bottom = top + @dropdown.offsetHeight
      select_top = getTop(@select) - pageOffsetTop
      select_bottom = select_top + @select.offsetHeight

      if dropdown_bottom < select_bottom
        @dropdown.style.top = dropdown_top + (select_bottom - dropdown_bottom) + 'px'
      else if dropdown_top > select_top
        @dropdown.style.top = dropdown_top - (dropdown_top - select_top)


  resize_dropdown: -> @dropdown.style.width = @select.offsetWidth + 'px'

  toggle: ->
    (if @open = !@open then addClass else removeClass)(@select, 'open')
    @resize_dropdown() if @settings.resizeDropdown
    @position_dropdown() if @settings.positionDropdown
    _(@options_by_char).each (options) -> options.sort()

  reset: (option) -> @default_selected[0].better_version.select() if @default_selected

  set_selected: (option) ->
    unless option
      @update()
    else
      unless @selected_option.innerHTML == option.innerHTML
        removeClass(@dropdown_selected_option, 'selected') if @dropdown_selected_option
        addClass @dropdown_selected_option = option, 'selected'
        @selected_option.innerHTML = option.innerHTML
        e = document.createEvent('Event')
        e.initEvent 'change', true, true
        @select.orig.dispatchEvent e
        @select.focus()

  option_template: '<div class="option"><%= innerHTML %></div>'
  option_group_template: '<div class="optgroup"><div class="option-group-label"><%= label %></div></div>'
  select_template: '<div class="select better-select"><a href="javascript:void(0)" class="selected-option"></a><div class="better-select-dropdown dropdown"></div></div>'
  process_option: (option) -> option
  process_option_group: (option_group) -> option_group
  process_select: (select) -> select

##############
# Extensions #
##############

extensions = []
BetterSelect.register_extension = (extensions) -> _(extensions).each (k, v) -> console.log(k, v)

window.BetterSelect = BetterSelect
