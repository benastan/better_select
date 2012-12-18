compile:
	coffee -co ./build ./lib/better-select.coffee
	sass lib/better-select.css.scss  > ./build/better-select.css

rails:
	cp lib/better-select.coffee assets/javascripts/better-select.js.coffee
	cp lib/better-select.css.scss assets/stylesheets/better-select.css.scss

