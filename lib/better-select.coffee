$$ = (html) ->
  elm = document.createElement 'div'
  elm.innerHTML = html
  if elm.children.length > 1 then elm.children else elm.children[0]

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

  option.addEventListener 'mouseover', -> option.better_select.set_focused option

  bs.options.push option
  first_char = option.innerHTML.substr(0, 1).toLowerCase()
  unless bs.options_by_first_char[first_char]
    bs.options_by_first_char[first_char] = []
    bs.options_by_first_char[first_char].sort = ->
      (sorted = _(@).sortBy 'innerHTML').unshift 0, @.length
      @.splice.apply @, sorted
  bs.options_by_first_char[first_char].push option
  bs.options_by_first_char[first_char].sort()
  option

renderOptionGroup = (orig_group, bs) ->
  group = build_element 'option_group', orig_group, bs
  group.appendChild(renderOption child, bs) for child in orig_group.children
  bs.option_groups.push group
  group

class BetterSelect

  defaults:
    positionDropdown: true

  constructor: (elm, options) ->
    return unless elm && elm.tagName && elm.tagName is 'SELECT'
    @settings = _.extend {}, @defaults, options
    @options = []
    @options_by_first_char = {}
    @option_groups = []
    selected = elm.selectedOptions
    @select = build_element 'select', elm, @
    [@selected_option, @dropdown] = @select.children

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
        @set_focused @dropdown_selected_option
      @toggle()

    window.addEventListener 'click', (e) =>
      unless e.target == @selected_option || e.target == @select || @options.indexOf(e.target) isnt -1
        @toggle() if @open

    @last_char = false

    @selected_option.addEventListener 'focus', =>
      document.body.style.overflow = 'hidden'
      addClass @select, 'focus'

    @selected_option.addEventListener 'blur', =>
      removeClass @select, 'focus'
      document.body.style.overflow = 'auto'
      @toggle() if @open is true
      true

    @selected_option.addEventListener 'keydown', (e) => e.preventDefault() unless [38, 40].indexOf(e.keyCode) is -1

    @selected_option.addEventListener 'keyup', (e) => @process_key_event(e)

    window.addEventListener 'keyup', (e) => @process_key_event(e) if @open

  focused_option: false
  focus_index: -1

  process_key_event: (e) ->
    keyCode = e.keyCode
    isNumber = keyCode > 47 && keyCode < 58
    isLetter = keyCode > 64 && keyCode < 91

    return unless [13, 38, 40].indexOf(keyCode) isnt -1 || isLetter || isNumber

    @toggle() if [13, 38, 40].indexOf(keyCode) isnt -1 && @open is false

    switch keyCode
      when 38 then @set_focused @options[if (@focus_index -= 1) < 0 then @focus_index = @options.length - 1 else @focus_index]
      when 40 then @set_focused @options[if (@focus_index += 1) >= @options.length then @focus_index = 0 else @focus_index]
      when 13 then @focused_option.select() if @focused_option
      else
        if isNumber
          char = numbers[new String(keyCode - 48)]
        else if isLetter
          char = letters[keyCode - 65]

        if char && @options_by_first_char[char]
          @toggle() unless @open
          @options_by_first_char[char].sort() unless @last_char is char
          option = @options_by_first_char[char].shift()
          @options_by_first_char[char].push option
          @set_focused option
          @focus_index = @options.indexOf option
          @last_char = char

    e.preventDefault()
    e.stopPropagation()
    e.returnValue = false

  set_focused: (option) ->
    class_for_selected = (option) => if @selected_option && option.innerHTML is @selected_option.innerHTML then " selected" else ""
    @focused_option.setAttribute('class', "option#{class_for_selected(@focused_option)}") if @focused_option
    @focused_option = option
    @focused_option.setAttribute("class", "option focus#{class_for_selected(option)}")
    @focus_index = @options.indexOf @focused_option

  open: false

  toggle: ->
    (if @open = !@open then addClass else removeClass)(@select, 'open')
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
  select_template: '<div class="select"><a href="javascript:void(0)" class="selected-option"></a><div class="better-select-dropdown dropdown"></div></div>'
  process_option: (option) -> option
  process_option_group: (option_group) -> option_group
  process_select: (select) -> select

window.BetterSelect = BetterSelect
