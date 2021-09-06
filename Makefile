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

.PHONY: test
test: ## run test suite
	poetry run python -m pytest -vv tests

.PHONY: build
build: ## build docker image
	docker build -t espn_my_matchup --ssh github_ssh_key=/Users/robertblumberg/.ssh/id_rsa  .

.PHONY: push
push: ## push docker image to ecr
	aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 978072805127.dkr.ecr.us-east-1.amazonaws.com
	docker tag espn_my_matchup:latest 978072805127.dkr.ecr.us-east-1.amazonaws.com/espn_my_matchup:latest
	docker push 978072805127.dkr.ecr.us-east-1.amazonaws.com/espn_my_matchup:latest
