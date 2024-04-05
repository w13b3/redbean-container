# # Makefile
.DEFAULT_GOAL := all
SHELL := /usr/bin/env sh


# # # Default variables
MODE ?= optlinux
REDBEAN_VERSION ?= latest

IMAGE_TAG ?= latest
DEBIAN_TAG ?= bookworm-20240311-slim
ALPINE_TAG ?= 3.19.1


# # # Help

.PHONY: help
help:
	@echo "Usage: make [TARGET:-all]"
	@echo "TARGET:"
	@echo "  all"
	@echo "  lint-dockerfile FILE"
	@echo "  lint-all"
	@echo "  redbean-build"


# # # Default goal

.PHONY: all
all: lint-all
	$(info Done running 'make all')


# # # Build

.PHONY: redbean-build
redbean-build:
	DOCKER_BUILDKIT=1 docker buildx build $(CURDIR) \
		--tag=$@:$(IMAGE_TAG) \
		--file=$(CURDIR)/Dockerfile.redbean-build \
		--build-arg=DEBIAN_TAG=$(DEBIAN_TAG) \
		--build-arg=MODE=$(MODE)


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
