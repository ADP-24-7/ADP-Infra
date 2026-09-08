SHELL := /bin/sh

TF_ENV_FILE ?= .env.terraform.local
COMPOSE_ENV := $(if $(wildcard $(TF_ENV_FILE)),--env-file $(TF_ENV_FILE),)
TF ?= docker compose $(COMPOSE_ENV) run --rm terraform
STATIC_TF_DATA_DIR ?= .terraform-static

.DEFAULT_GOAL := help

.PHONY: help env version init-static init-local init-remote fmt validate check plan import-plan state-list

help:
	@printf "%s\n" \
		"ADP-Infra commands:" \
		"  make env          Create a permission-restricted local credential file" \
		"  make version      Show the pinned Terraform version" \
		"  make init-local   Initialize the local backend for first adoption" \
		"  make init-remote  Migrate local state to NCP Object Storage" \
		"  make fmt          Format all Terraform configuration" \
		"  make validate     Validate the QA configuration offline from NCP" \
		"  make check        Run format check and validation" \
		"  make import-plan  Preview adoption of existing console resources" \
		"  make plan         Create a normal QA plan" \
		"  make state-list   List resources already tracked in state" \
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

init-remote:
	cp environments/qa/backend.tf.example environments/qa/backend.tf
	$(TF) init -migrate-state -backend-config=backend.hcl.example

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
