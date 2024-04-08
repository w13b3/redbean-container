# # Makefile
.DEFAULT_GOAL := all
SHELL := /usr/bin/env sh


# # # Default variables

COSMOPOLITAN_REPO = https://github.com/jart/cosmopolitan
# # if COSMOPOLITAN_SHA is given, the Dockerfile will reset the git repo to that commit
COSMOPOLITAN_SHA ?=
ifeq ($(COSMOPOLITAN_SHA),)
# # COSMOPOLITAN_SHA is not given
COSMOPOLITAN_SHORT_SHA = $(shell git ls-remote --quiet --head $(COSMOPOLITAN_REPO).git master | cut -c 1-6)
else
# # COSMOPOLITAN_SHA is given
COSMOPOLITAN_SHORT_SHA = $(shell echo $(COSMOPOLITAN_SHA) | cut -c 1-6)
endif

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
	@echo "  redbean-scratch"


# # # Default goal

.PHONY: all
all: redbean-scratch
	$(info Done running 'make all')


# # # Build

.PHONY: redbean
redbean: redbean-scratch
	$(info Done running 'make redbean')

# # Make an image only containing redbean
.PHONY: redbean-scratch
redbean-scratch:
	DOCKER_BUILDKIT=1 docker buildx build $(CURDIR) \
		--load \
		--file=$(CURDIR)/Dockerfile.redbean \
		--build-arg=BUILD_DEBIAN_TAG=$(BUILD_DEBIAN_TAG) \
		--build-arg=MODE=$(MODE) \
		--build-arg=COSMOPOLITAN_SHA=$(COSMOPOLITAN_SHA) \
		--tag=redbean:$(MODE) \
		--tag=redbean:$(MODE)-$(COSMOPOLITAN_SHORT_SHA) \
		--tag=ghcr.io/$(GIT_REPO_OWNER)/redbean:$(MODE) \
		--tag=ghcr.io/$(GIT_REPO_OWNER)/redbean:$(MODE)-$(COSMOPOLITAN_SHORT_SHA)


# # # Lint the Dockerfile

# # Usage: make lint-dockerfile FILE=./Dockerfile
.PHONY: lint-dockerfile
lint-dockerfile:
ifeq ($(origin FILE), undefined)
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
