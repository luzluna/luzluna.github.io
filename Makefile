test:
	bundle exec /usr/local/bin/jekyll serve -H 0
build:
	bundle exec /usr/local/bin/jekyll build
deploy: build
	git push
