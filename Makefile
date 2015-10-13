test:
	jekyll serve -H 0
build:
	jekyll build
deploy: build
	git push
