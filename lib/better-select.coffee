$$ = (html) ->
  elm = document.createElement 'div'
  elm.innerHTML = html
  if elm.children.length > 1 then elm.children else elm.children[0]

build_element = (what, orig, obj) ->
  elm = $$ _.template(obj["#{what}_template"]) obj["process_#{what}"] orig
  elm.orig = orig
  orig.better_version = elm
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
    bs.toggle() if bs.select.getAttribute('class').indexOf('open') isnt -1
    bs.set_selected @
  option.addEventListener 'click', -> @select()
  bs.options.push option
  option

renderOptionGroup = (orig_group, bs) ->
  group = build_element 'option_group', orig_group, bs
  group.appendChild(renderOption child, bs) for child in orig_group.children
  bs.option_groups.push group
  group

class BetterSelect
  constructor: (elm) ->
    selected = elm.selectedOptions
    @select = build_element 'select', elm, @
    [@selected_option, @dropdown] = @select.children
    @default_selected = elm.selectedOptions
    children = elm.children
    for child in children
      switch child.tagName
        when 'OPTION'
          method = renderOption
        when 'OPTGROUP'
          method = renderOptionGroup
      @dropdown.appendChild(method child, @)
    @default_selected[0].better_version.select()
    elm.parentNode.insertBefore @select, elm
    elm.parentNode.insertBefore elm, @select
    elm.style.display = 'none'
    @selected_option.addEventListener 'click', => @toggle()
  open: false
  toggle: -> @select.setAttribute 'class', if @open = !@open then 'select open' else 'select'
  reset: (option) -> @default_selected[0].better_version.select()
  set_selected: (option) -> @selected_option.innerHTML = option.innerHTML
  options: []
  option_groups: []
  option_template: '<div class="option"><%= innerHTML %></div>'
  option_group_template: '<div class="optgroup"><div class="option-group-label"><%= label %></div></div>'
  select_template: '<div class="select"><div class="selected-option"></div><div class="dropdown"></div></div>'
  process_option: (option) -> option
  process_option_group: (option_group) -> option_group
  process_select: (select) -> select
