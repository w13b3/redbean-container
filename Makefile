# # Makefile
.DEFAULT_GOAL := all
SHELL := /usr/bin/env sh


# # # Default variables

MODE ?= optlinux
REDBEAN_VERSION ?= latest

BUILD_TAG ?= latest
BUILD_DEBIAN_TAG ?= bookworm-20240311-slim
ALPINE_TAG ?= 3.19.1

GIT_REPO_OWNER ?= none


# # # Help

.PHONY: help
help:
	@echo "Usage: make [TARGET:-all]"
	@echo "TARGET:"
	@echo "  all"
	@echo "  lint-dockerfile FILE"
	@echo "  lint-all"
	@echo "  redbean"
	@echo "  redbean-build"
	@echo "  redbean-alpine"
	@echo "  redbean-scratch"


# # # Default goal

.PHONY: all
all: redbean
	$(info Done running 'make all')


# # # Build

.PHONY: redbean
redbean: redbean-scratch
	$(info Done running 'make redbean')

.PHONY: redbean-build
redbean-build:
	DOCKER_BUILDKIT=1 docker buildx build $(CURDIR) \
		--load \
		--file=$(CURDIR)/Dockerfile.redbean-build \
		--build-arg=MODE=$(MODE) \
		--build-arg=BUILD_DEBIAN_TAG=$(BUILD_DEBIAN_TAG) \
		--tag=redbean-build:$(BUILD_TAG) \
		--tag=ghcr.io/$(GIT_REPO_OWNER)/redbean-build:$(BUILD_TAG)

redbean-alpine: redbean-build
	DOCKER_BUILDKIT=1 docker buildx build $(CURDIR) \
		--load \
		--file=$(CURDIR)/Dockerfile.redbean-alpine \	
		--build-arg=ALPINE_TAG=$(ALPINE_TAG) \
		--build-arg=GIT_REPO_OWNER=$(GIT_REPO_OWNER) \
		--build-arg=BUILD_TAG=$(BUILD_TAG) \
		--tag=redbean:$(REDBEAN_VERSION)-alpine \
		--tag=ghcr.io/$(GIT_REPO_OWNER)/redbean:$(REDBEAN_VERSION)-alpine

redbean-scratch: redbean-build
	DOCKER_BUILDKIT=1 docker buildx build $(CURDIR) \
		--load \
		--file=$(CURDIR)/Dockerfile.redbean-scratch \
		--build-arg=GIT_REPO_OWNER=$(GIT_REPO_OWNER) \
		--build-arg=BUILD_TAG=$(BUILD_TAG) \
		--tag=redbean:$(REDBEAN_VERSION) \
		--tag=ghcr.io/$(GIT_REPO_OWNER)/redbean:$(REDBEAN_VERSION)


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
	$(info No errors found in '$(FILE)')
endif

.PHONY: lint-all lint-all-%
lint-all: $(foreach FILE, $(wildcard $(CURDIR)/Dockerfile*), lint-all-$(notdir $(FILE)))
lint-all-%:
	$(MAKE) lint-dockerfile FILE=$(CURDIR)/$*
