test:
	bin/rails test

setup:
	bin/setup

lint:
	bundle exec rubocop
	bundle exec slim-lint app/views/

.PHONY: test