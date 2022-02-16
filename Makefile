.PHONY: init
init: ## install poetry and dev deps
	pip install --user poetry
	poetry install
	poetry env use python
	poetry shell

.PHONY: format
format: ## run code formatters
	poetry run isort -rc -sp .isort.cfg .
	poetry run black .

.PHONY: check_format
check_format: ## check for code formatter errors
	poetry run flake8

.PHONY: test
test: ## run test suite
	poetry run python -m pytest -vv tests

.PHONY: build_image
build_image: ## build docker image
	docker build -t espn_my_matchup --ssh github_ssh_key=/Users/robertblumberg/.ssh/id_rsa  --no-cache .

.PHONY: push_image
push_image: ## push docker image to ecr
	aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 978072805127.dkr.ecr.us-west-2.amazonaws.com
	docker tag espn_my_matchup:latest 978072805127.dkr.ecr.us-west-2.amazonaws.com/espn_my_matchup:latest
	docker push 978072805127.dkr.ecr.us-west-2.amazonaws.com/espn_my_matchup:latest

.PHONY: build_app_image
build_app_image: ## build docker image
	docker build -t fantasy_app -f fantasy_application/Dockerfile --ssh github_ssh_key=/Users/robertblumberg/.ssh/id_rsa --no-cache .

.PHONY: push_app_image
push_app_image: ## push docker image to ecr
	aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 978072805127.dkr.ecr.us-west-2.amazonaws.com
	docker tag fantasy_app:latest 978072805127.dkr.ecr.us-west-1.amazonaws.com/fantasy_app:latest
	docker push 978072805127.dkr.ecr.us-west-2.amazonaws.com/fantasy_app:latest