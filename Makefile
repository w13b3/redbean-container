# # Makefile
.DEFAULT_GOAL := all
SHELL := /usr/bin/env sh


# # # Help

.PHONY: help
help:
	@echo "Usage: make [TARGET:-all]"
	@echo "TARGET:"
	@echo "  all"
	@echo "  lint-dockerfile FILE"
	@echo "  lint-all"


# # # Default goal

.PHONY: all
all: lint-all
	$(info Done running 'make all')


# # # Lint the Dockerfile

.PHONY: lint-dockerfile
lint-dockerfile:
ifeq ($(origin FILE), undefined)
	@# Usage: make lint-dockerfile FILE=./Dockerfile
	$(error variable FILE is not set)
else
	docker run \
		--rm \
		--interactive \
		--network=none \
		--volume="$(CURDIR)/.hadolint.yml:/.hadolint.yml:ro" \
		hadolint/hadolint < $(FILE)
endif
	

.PHONY: lint-all lint-all-%
lint-all: $(foreach FILE, $(wildcard $(CURDIR)/Dockerfile*), lint-all-$(notdir $(FILE)))
lint-all-%:
	$(MAKE) lint-dockerfile FILE=$(CURDIR)/$*
