$$ = (html) ->
  elm = document.createElement 'div'
  elm.innerHTML = html
  if elm.children.length > 1 then elm.children else elm.children[0]

chrome = /AppleWebKit\/(.+)Chrome/.test navigator.userAgent
moz = /Gecko\//.test navigator.userAgent

getPos = (tgt, method) ->
  pos = 0
  while tgt
    pos += tgt[method]
    tgt = tgt.offsetParent
  pos

getTop = (tgt) -> getPos tgt, 'offsetTop'
getLeft = (tgt) -> getPos tgt, 'offsetLeft'

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

letters = 'a b c d e f g h i j k l m n o p q r s t u v w x y z'.split ' '
numbers = '0 1 2 3 4 5 6 7 8 9 0'.split ' '

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

  option.addEventListener 'click', ->
    option.select()

  option.focus = -> bs.set_focused option

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

extensions = []

class BetterSelect
  defaults:
    positionDropdown: true
    resizeDropdown: true

  constructor: (elm, options) ->
    return unless elm && elm.tagName && elm.tagName is 'SELECT'
    @settings = _.extend {}, @defaults, options
    @options = []
    @options_by_char = {}
    @option_groups = []
    selected = elm.selectedOptions
    @select = build_element 'select', elm, @
    [@selected_option, @dropdown] = @select.children
    @selected_option.better_select = @

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
        @dropdown_selected_option.focus()
      @toggle()

    window.addEventListener 'click', (e) =>
      unless e.target == @selected_option || e.target == @select || @options.indexOf(e.target) isnt -1
        @toggle() if @open

    @last_char = false

    event_tgt = @select

    event_tgt.addEventListener 'focus', => addClass @select, 'focus'

    event_tgt.addEventListener 'blur', (e) =>
      if tgt = e.explicitOriginalTarget
        tgt = tgt.parentNode unless tgt.tagName is 'DIV'
        @set_selected tgt unless @options.indexOf(tgt) is -1
      removeClass @select, 'focus'
      document.body.style.overflow = 'auto'
      @toggle() if @open is true
      true

    event_tgt.addEventListener 'keyup', (e) => e.preventDefault() unless [38, 40].indexOf(e.keyCode) is -1

    event_tgt.addEventListener 'keydown', (e) => @process_key_event(e)

    window.addEventListener 'keydown', (e) => @process_key_event(e) if @open

    @select.tabIndex = 0
    @selected_option.tabIndex = -1

  focused_option: false
  focus_index: -1
  select_focused: -> @focused_option.select() if @focused_option

  process_key_event: (e) ->
    keyCode = e.keyCode
    isNumber = keyCode > 47 && keyCode < 58
    isLetter = keyCode > 64 && keyCode < 91

    return @select_focused() if keyCode is 9 && @open

    return unless [13, 38, 40].indexOf(keyCode) isnt -1 || isLetter || isNumber

    @toggle() if [13, 38, 40].indexOf(keyCode) isnt -1 && @open is false

    switch keyCode
      when 38 then @options[if (@focus_index -= 1) < 0 then @focus_index = @options.length - 1 else @focus_index].focus()
      when 40 then @options[if (@focus_index += 1) >= @options.length then @focus_index = 0 else @focus_index].focus()
      when 13 then @select_focused()
      else
        if isNumber
          char = numbers[new String(keyCode - 48)]
        else if isLetter
          char = letters[keyCode - 65]

        keys_pressed = _keys_pressed = @keys_pressed = "#{@keys_pressed || ''}#{char}"
        _.delay (-> @keys_pressed = '' if _keys_pressed is @keys_pressed ), 3000

        if char
          while keys_pressed.length
            if @options_by_char[keys_pressed]
              @toggle() unless @open
              @options_by_char[keys_pressed].sort() unless @last_char is char
              option = @options_by_char[keys_pressed].shift()
              @options_by_char[keys_pressed].push option
              option.focus()
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
    @focused_option.scroll_by() if @adjust_height

  open: false

  toggle: ->
    (if @open = !@open then addClass else removeClass)(@select, 'open')
    if @settings.resizeDropdown
      @dropdown.style.width = @select.offsetWidth + 'px'
    if @settings.positionDropdown
      if @dropdown.offsetHeight > window.innerHeight
        height = window.innerHeight * .50
        @dropdown.style.height = height + 'px'
        @dropdown.style['overflow-y'] = 'auto'
        if @dropdown_selected_option.offsetTop > height || @adjust_height
          @dropdown_selected_option.scrollIntoView()
          @adjust_height = true
      top = top || (getTop(@select) - @dropdown_selected_option.offsetTop)
      top = getTop(@select) - (@dropdown_selected_option.offsetTop - @dropdown.scrollTop)
      @dropdown.style.top = (if top < 0 then 0 else top)  + 'px'
      @dropdown.style.left = if @open then getLeft(@select) + 'px' else '-9999px'
    _(@options_by_char).each (options) -> options.sort()

  reset: (option) -> @default_selected[0].better_version.select() if @default_selected

  set_selected: (option) ->
    unless @selected_option.innerHTML == option.innerHTML
      removeClass(@dropdown_selected_option, 'selected') if @dropdown_selected_option
      addClass @dropdown_selected_option = option, 'selected'
      @selected_option.innerHTML = option.innerHTML
      e = document.createEvent('Event')
      e.initEvent 'change', true, true
      @select.orig.dispatchEvent e
    @selected_option.focus()

  option_template: '<div class="option"><%= innerHTML %></div>'
  option_group_template: '<div class="optgroup"><div class="option-group-label"><%= label %></div></div>'
  select_template: '<div class="select better-select"><a href="javascript:void(0)" class="selected-option"></a><div class="better-select-dropdown dropdown"></div></div>'
  process_option: (option) -> option
  process_option_group: (option_group) -> option_group
  process_select: (select) -> select

BetterSelect.register_extension = (extensions) -> _(extensions).each (k, v) -> console.log(k, v)

window.BetterSelect = BetterSelect
