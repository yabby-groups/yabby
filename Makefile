JSX_SOURCE=src/jsx/header.js src/jsx/util.js src/jsx/file.js src/jsx/tweet.js \
					 src/jsx/pagenavi.js src/jsx/main.js

all: public/static/js/main.js public/static/style.css
	@cake build

public/static/js/main.js: src/jsx/main.js
	cat $(JSX_SOURCE) > comibed.js
	browserify -t [ reactify --es6  ] comibed.js | uglifyjs -m -r '$$' > $@

public/static/style.css: src/less/style.less
	lessc $^ > $@

clean:
	rm -f public/static/js/main.js public/static/style.css
	@cake clean
