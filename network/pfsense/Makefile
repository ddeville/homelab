.DEFAULT_GOAL := configure

.PHONY: setup
setup:
	ansible-galaxy collection install -r requirements.yaml

.PHONY: bootstrap
bootstrap: setup
	ansible-playbook playbooks/bootstrap.yaml

.PHONY: configure
configure: setup
	ansible-playbook playbooks/configure.yaml
