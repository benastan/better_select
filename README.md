# BetterSelect

HTML5 still hasn't gotten these right. Here's a simple JavaScript HTMLSelectElement
replacer.

## Installation

Add to HTML web page:
    
    <!-- Underscore is BetterSelect's only dependency -->
    <script type="text/javascript" src="http://underscorejs.org/underscore-min.js"></script>
    <script type="text/javascript" src="https://raw.github.com/benastan/better_select/master/build/better-select.js"></script>

Or clone source:

    git clone git@github.com:benastan/better_select.git

## Usage

Plain JavaScript:

  <select id="boring-select"><option>What a bore!</option><option>This
is boring!</option></select>
  
    boring_select = document.getElementById('boring-select')
    better_select = new BetterSelect(boring_select)

The BetterSelect instance offers a number of helpful properties, for
example:

    better_select.select // HTML Element of the replacement select.
    better_select.dropdown // HTML Element containing the new options list.
    better_select.selected_option // HTML Element containing the new options list.

BetterSelect doesn't interfere with how the original select element
operates. When the form submits, the value still comes from the select
element itself.

Additionally, you can attach events to the original element the same way
as always:

    ChangeHandler = function() { alert("It changed!") }
    boring_select.addEventListener('change', ChangeHandler)

Or, with jQuery:

    $(boring_select).on('change', ChangeHandler)

## CSS

BetterSelect comes with a very limited amount of CSS -- just enough to
make BetterSelect functional. All other styling choices are up to you.

## TODO

1. There are still a few ways that BetterSelect does not quite feel like
   a standard select element. One is that when you type out a value when
   focused, BetterSelect only focuses based on the first letter.
2. Create themes.
3. Code clean up.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
