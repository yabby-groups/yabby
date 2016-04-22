BIN=node_modules/.bin
BABEL=$(BIN)/babel --presets=react
CAKE=$(BIN)/cake
UGLIFYJS=$(BIN)/uglifyjs -m -r
LESSC=$(BIN)/lessc
BROWSERIFY=$(BIN)/browserify
COMBINED=combine.js

JSX_SOURCE=src/jsx/header.js src/jsx/util.js src/jsx/file.js src/jsx/tweet.js \
					 src/jsx/pagenavi.js src/jsx/main.js

all: public/static/js/main.js public/static/style.css
	@$(CAKE) build

public/static/js/main.js: src/jsx/main.js
	cat $(JSX_SOURCE) | $(BABEL) > $(COMBINED)
	$(BROWSERIFY) $(COMBINED) | $(UGLIFYJS) '$$' > $@

public/static/style.css: src/less/style.less
	$(LESSC) $^ > $@

clean:
	rm -f public/static/js/main.js public/static/style.css
	@$(CAKE) clean
