ANSIBLE_PLAYBOOK ?= ansible-playbook
S ?=

.DEFAULT_GOAL := help
.PHONY: help deploy app env data

help:  ## показать цели
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*##/\t/' | expand -t 12

deploy: ## все сервисы или один (S=budget): пользователь, код, .env, служба, HTTPS
	$(ANSIBLE_PLAYBOOK) site.yml -e only=$(S)

app: ## только код сервиса S: git pull, зависимости, рестарт
	$(ANSIBLE_PLAYBOOK) site.yml --tags app -e only=$(S)

env: ## задать ключ K в .env сервиса S (значение спросит)
	$(ANSIBLE_PLAYBOOK) env.yml -e only=$(S) -e key=$(K)

data: ## перенести базы сервиса S из локальной папки FROM поверх серверных
	@printf "Базы %s на сервере заменятся копией из %s. Продолжить? [y/N] " "$(S)" "$(FROM)"; read a; [ "$$a" = y ]
	$(ANSIBLE_PLAYBOOK) data.yml -e only=$(S) -e from=$(FROM)
