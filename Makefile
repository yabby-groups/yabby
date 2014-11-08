all: public/static/js/main.js public/static/style.css
	@cake build

public/static/js/main.js: src/jsx/main.js
	browserify -t [ reactify --es6  ] $< | uglifyjs -m -r '$$' > $@

public/static/style.css: src/less/style.less
	lessc $^ > $@

clean:
	rm -f public/static/js/main.js public/static/style.css
	@cake clean
