SHELL := /bin/sh

TF_ENV_FILE ?= .env.terraform.local
COMPOSE_ENV := $(if $(wildcard $(TF_ENV_FILE)),--env-file $(TF_ENV_FILE),)
COMPOSE ?= docker compose $(COMPOSE_ENV)
TF ?= $(COMPOSE) run --rm terraform
STATIC_TF_DATA_DIR ?= .terraform-static

.DEFAULT_GOAL := help

.PHONY: help env version init-static init-local recover-local-state init-remote fmt validate check plan import-plan state-list state-verify verify-remote

help:
	@printf "%s\n" \
		"ADP-Infra commands:" \
		"  make env          Create a permission-restricted local credential file" \
		"  make version      Show the pinned Terraform version" \
		"  make init-local   Initialize the local backend for first adoption" \
		"  make recover-local-state  Restore an interrupted adoption from the local backup" \
		"  make init-remote  Migrate local state to NCP Object Storage" \
		"  make fmt          Format all Terraform configuration" \
		"  make validate     Validate the QA configuration offline from NCP" \
		"  make check        Run format check and validation" \
		"  make import-plan  Preview adoption of existing console resources" \
		"  make plan         Create a normal QA plan" \
		"  make state-list   List resources already tracked in state" \
		"  make state-verify Require exactly the five adopted resource addresses" \
		"  make verify-remote  Require five remote resources and a zero-change plan" \
		"" \
		"Use TF='terraform -chdir=environments/qa' for a compatible native CLI."

env:
	@test -f $(TF_ENV_FILE) || cp .env.terraform.local.example $(TF_ENV_FILE)
	@chmod 600 $(TF_ENV_FILE)
	@printf "%s\n" "Prepared $(TF_ENV_FILE) with mode 600. Add credentials locally; never commit it."

version:
	$(TF) version

init-static:
	TF_DATA_DIR=$(STATIC_TF_DATA_DIR) $(TF) init -backend=false

init-local:
	@test ! -f environments/qa/backend.tf || (printf "%s\n" "Remove environments/qa/backend.tf only if intentionally returning to local state."; exit 1)
	$(TF) init -reconfigure

recover-local-state:
	@test -s environments/qa/terraform.tfstate.backup || (printf "%s\n" "A non-empty environments/qa/terraform.tfstate.backup is required."; exit 1)
	@umask 077; cp environments/qa/terraform.tfstate.backup environments/qa/terraform.tfstate.pre-recovery
	@rm -f environments/qa/backend.tf
	@umask 077; cp environments/qa/terraform.tfstate.backup environments/qa/terraform.tfstate
	@chmod 600 environments/qa/terraform.tfstate.backup environments/qa/terraform.tfstate.pre-recovery environments/qa/terraform.tfstate
	@$(COMPOSE) run --rm --entrypoint sh terraform -c 'rm -f "$$TF_DATA_DIR/terraform.tfstate"'
	$(TF) init -reconfigure
	$(MAKE) state-verify

init-remote:
	@test ! -f environments/qa/backend.tf || (printf "%s\n" "Remote backend is already active or a previous migration was interrupted. Verify state before retrying."; exit 1)
	@test -s environments/qa/terraform.tfstate || (printf "%s\n" "A non-empty local state is required before remote migration."; exit 1)
	@$(MAKE) state-verify
	@umask 077; cp environments/qa/terraform.tfstate environments/qa/terraform.tfstate.pre-remote
	@cp environments/qa/backend.tf.example environments/qa/backend.tf
	@$(TF) init -migrate-state -backend-config=backend.hcl.example || { \
		status=$$?; \
		printf "%s\n" "Remote migration failed; restoring the preserved local state."; \
		rm -f environments/qa/backend.tf; \
		cp environments/qa/terraform.tfstate.pre-remote environments/qa/terraform.tfstate; \
		chmod 600 environments/qa/terraform.tfstate; \
		$(COMPOSE) run --rm --entrypoint sh terraform -c 'rm -f "$$TF_DATA_DIR/terraform.tfstate"'; \
		$(TF) init -reconfigure; \
		exit $$status; \
	}

fmt:
	$(TF) fmt -recursive ../..

validate: init-static
	TF_DATA_DIR=$(STATIC_TF_DATA_DIR) $(TF) validate

check:
	$(TF) fmt -check -recursive ../..
	$(MAKE) validate

import-plan: init-local
	@rm -f environments/qa/adoption.tfplan
	$(TF) plan -out=adoption.tfplan

plan:
	@test -f environments/qa/backend.tf || (printf "%s\n" "Remote backend is not active. Finish adoption, then run make init-remote first."; exit 1)
	$(TF) plan

state-list:
	$(TF) state list

state-verify:
	@$(TF) state list | LC_ALL=C sort | diff -u environments/qa/expected-state.txt -

verify-remote:
	@test -f environments/qa/backend.tf || (printf "%s\n" "Remote backend is not active. Run make init-remote after local adoption."; exit 1)
	$(MAKE) state-verify
	$(TF) plan -detailed-exitcode
