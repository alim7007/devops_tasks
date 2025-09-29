SHELL := /bin/bash

VENV := .venv
PY := $(VENV)/bin/python
PIP := $(VENV)/bin/pip
ANSIBLE := $(VENV)/bin/ansible
ANSIBLE_PLAYBOOK := $(VENV)/bin/ansible-playbook
GALAXY := $(VENV)/bin/ansible-galaxy

export ANSIBLE_CONFIG := $(CURDIR)/ansible.cfg

.PHONY: help bootstrap venv galaxy-install galaxy-update check apply tags clean clean-all shell

help:
	@echo "make bootstrap      # create venv, install pins, vendor galaxy deps"
	@echo "make check          # dry-run playbook (no changes)"
	@echo "make apply          # run full setup.yaml"
	@echo "make tags TAG=app   # run only a tag (base|nginx|app|ssh)"
	@echo "make shell          # drop into venv shell"
	@echo "make clean          # remove venv only"
	@echo "make clean-all      # remove venv and vendored deps"

venv:
	@test -d $(VENV) || (python3 -m venv $(VENV) && \
		$(PIP) install --upgrade pip && \
		$(PIP) install -r ansible/requirements/ansible.txt)

galaxy-install:
	@mkdir -p ansible/vendor/roles ansible/vendor/collections
	$(GALAXY) collection install -r ansible/requirements/collections.yaml -p ansible/vendor/collections
	@if test -s ansible/requirements/roles.yaml; then \
		$(GALAXY) role install -r ansible/requirements/roles.yaml -p ansible/vendor/roles; \
	fi

galaxy-update:
	$(GALAXY) collection install -r ansible/requirements/collections.yaml -p ansible/vendor/collections --force
	@if test -s ansible/requirements/roles.yaml; then \
		$(GALAXY) role install -r ansible/requirements/roles.yaml -p ansible/vendor/roles --force; \
	fi

bootstrap: venv galaxy-install
	@$(ANSIBLE) --version

check:
	$(ANSIBLE_PLAYBOOK) ansible/playbooks/setup.yaml --limit server2 --check --diff

apply:
	$(ANSIBLE_PLAYBOOK) ansible/playbooks/setup.yaml --limit server2

tags:
	@if [ -z "$(TAG)" ]; then echo "Usage: make tags TAG=app|nginx|base|ssh"; exit 1; fi
	$(ANSIBLE_PLAYBOOK) ansible/playbooks/setup.yaml --tags "$(TAG)" --limit server2

shell:
	@echo "source $(VENV)/bin/activate"
	@bash --rcfile <(echo "source $(VENV)/bin/activate")

clean:
	rm -rf $(VENV)

clean-all: clean
	rm -rf ansible/vendor
