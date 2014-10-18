all: public/static/js/main.js public/static/style.css
	@cake build

public/static/js/main.js: src/jsx/main.jsx src/lib/util.coffee
	jsx src/jsx/main.jsx > $@
	browserify $@ -o /tmp/bounde.js
	uglifyjs /tmp/bounde.js -m -r '$$' > $@

public/static/style.css: src/less/style.less
	lessc $^ > $@

clean:
	rm -f public/static/js/main.js public/static/style.css
	@cake clean
