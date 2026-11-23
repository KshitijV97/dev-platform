SHELL := /bin/bash
COMPOSE := docker compose -f compose/compose.yaml --env-file .env

.PHONY: help check fmt up down logs ps deploy backup restore labels

help:
	@echo "make check    validate compose, terraform formatting, and shell scripts"
	@echo "make fmt      format terraform"
	@echo "make up       start the stack"
	@echo "make down     stop the stack"
	@echo "make logs     follow logs"
	@echo "make deploy   pull and restart services"
	@echo "make backup   dump postgres and run restic"
	@echo "make restore  restore the latest postgres dump (interactive)"
	@echo "make labels   create or update issue labels with gh"

check:
	docker compose -f compose/compose.yaml --env-file .env.example config >/dev/null
	terraform fmt -check -recursive infra
	shellcheck scripts/*.sh

fmt:
	terraform fmt -recursive infra

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f --tail=200

ps:
	$(COMPOSE) ps

deploy:
	./scripts/deploy.sh

backup:
	./scripts/backup.sh

restore:
	./scripts/restore.sh

labels:
	./scripts/create-labels.sh
