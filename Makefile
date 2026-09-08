SHELL := /bin/sh

TF ?= docker compose run --rm terraform

.DEFAULT_GOAL := help

.PHONY: help version init-static init-local init-remote fmt validate check plan import-plan state-list

help:
	@printf "%s\n" \
		"ADP-Infra commands:" \
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

version:
	$(TF) version

init-static:
	$(TF) init -backend=false

init-local:
	@test ! -f environments/qa/backend.tf || (printf "%s\n" "Remove environments/qa/backend.tf only if intentionally returning to local state."; exit 1)
	$(TF) init -reconfigure

init-remote:
	cp environments/qa/backend.tf.example environments/qa/backend.tf
	$(TF) init -migrate-state -backend-config=backend.hcl.example

fmt:
	$(TF) fmt -recursive ../..

validate: init-static
	$(TF) validate

check:
	$(TF) fmt -check -recursive ../..
	$(MAKE) validate

import-plan: init-local
	$(TF) plan -out=adoption.tfplan

plan:
	@test -f environments/qa/backend.tf || (printf "%s\n" "Remote backend is not active. Finish adoption, then run make init-remote first."; exit 1)
	$(TF) plan

state-list:
	$(TF) state list
