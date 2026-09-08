SHELL := /bin/sh

TF ?= docker compose run --rm terraform

.DEFAULT_GOAL := help

.PHONY: help version init-local init-remote fmt validate check plan import-plan state-list

help:
	@printf "%s\n" \
		"ADP-Infra commands:" \
		"  make version      Show the pinned Terraform version" \
		"  make init-local   Initialize without the remote backend" \
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

init-local:
	$(TF) init -backend=false

init-remote:
	$(TF) init -migrate-state -backend-config=backend.hcl.example

fmt:
	$(TF) fmt -recursive ../..

validate: init-local
	$(TF) validate

check:
	$(TF) fmt -check -recursive ../..
	$(MAKE) validate

import-plan: init-local
	$(TF) plan -out=adoption.tfplan

plan:
	$(TF) plan

state-list:
	$(TF) state list
