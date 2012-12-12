build:
	coffee -co javascripts ./lib/better-select.coffee
	sass lib/better-select.css.scss  > stylesheets/better-select.css

