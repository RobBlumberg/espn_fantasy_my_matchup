.PHONY: init
init: ## install poetry and dev deps
	pip install --user poetry
	poetry install
	poetry env use python
	poetry shell

.PHONY: format
format: ## run code formatters
	poetry run black .

.PHONY: check_format
check_format: ## check for code formatter errors
	poetry run flake8

#.PHONY: test
#test: ## run test suite
#	poetry run python -m pytest -vv tests

#.PHONY: coverage
#coverage: ## run test suite and output coverage files
	# poetry run python -m pytest \
	# 	--verbose \
	# 	--cov-report term \
	# 	--cov-report html:coverage/html \
	# 	--cov-report xml:coverage/coverage.xml \
	# 	--cov-report annotate:coverage/annotate \
	# 	--cov=va_framework \
	# 	tests