compile:
	coffee -co ./build ./lib/better-select.coffee
	sass lib/better-select.css.scss  > ./build/better-select.css

