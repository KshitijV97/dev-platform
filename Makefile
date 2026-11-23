SHELL := /bin/bash
COMPOSE := docker compose -f compose/compose.yaml --env-file .env

.PHONY: help check fmt up down logs ps deploy backup restore labels seed-issues iteration iteration-check export

help:
	@echo "make check            validate compose, terraform formatting, shell scripts, manifest"
	@echo "make fmt              format terraform"
	@echo "make up               start the stack"
	@echo "make down             stop the stack"
	@echo "make logs             follow logs"
	@echo "make deploy           pull and restart services"
	@echo "make backup           dump postgres and run restic"
	@echo "make restore          restore the latest postgres dump (interactive)"
	@echo "make labels           create or update issue labels with gh"
	@echo "make seed-issues      create iteration milestones and issues from the manifest"
	@echo "make iteration        show open issues per iteration"
	@echo "make iteration-check  fail if a required iteration still has open issues"
	@echo "make export           snapshot issues, labels, and milestones for the FOSS exit"

check:
	docker compose -f compose/compose.yaml --env-file .env.example config >/dev/null
	terraform fmt -check -recursive infra
	shellcheck scripts/*.sh
	jq -e . docs/iterations/manifest.json >/dev/null

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

seed-issues:
	./scripts/seed-issues.sh

iteration:
	./scripts/iteration-status.sh

iteration-check:
	./scripts/iteration-status.sh --check

export:
	./scripts/export-issues.sh
