all: public/static/js/main.js
	@cake build

public/static/js/main.js: src/jsx/main.jsx
	jsx $^ > $@

clean:
	@cake clean
