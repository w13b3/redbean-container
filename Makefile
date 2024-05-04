# # Makefile
.DEFAULT_GOAL := all
SHELL := /bin/sh


# # # Default variables

# # if REPO_SHA is given, the Dockerfile will reset the git repo to that commit
REPO_SHA ?=
DEFAULT_MODE ?= optlinux
BUILD_MODES ?= optlinux tinylinux asan rel
REGISTRY_OWNER ?= none


# # # Help

.PHONY: help
help:
	@echo "Usage: make [TARGET: all]"
	@echo ""
	@echo "TARGET:     [OPTION: default]"
	@echo "  help"
	@echo "  all"
	@echo "  build     [MODE: $(DEFAULT_MODE)]"
	@echo "  build-all [BUILD_MODES: $(BUILD_MODES)]"


# # # Default goal

.PHONY: all
all: build
	$(info Done running 'make all')


# # # Build

# # Build redbean in the given MODE (default: $(DEFAULT_MODE))
.PHONY: build
build:
ifeq ($(origin MODE), undefined)
	$(warning variable MODE is not set. MODE set to $(DEFAULT_MODE))
	$(MAKE) --directory=$(CURDIR) build MODE=$(DEFAULT_MODE)
else
	$(info Building in '$(MODE)' mode)
	DOCKER_BUILDKIT=1 MODE=$(MODE) REPO_SHA=$(REPO_SHA) \
		docker buildx bake --load --progress=plain scratch
endif

# # Build redbean in all the BUILD_MODES
.PHONY: build-all build-all-%
build-all: $(foreach M, $(BUILD_MODES), build-all-$(M))
build-all-%:
	$(MAKE) --directory=$(CURDIR) build MODE=$*


# # Downloads a copy of the repo in a debian container
.PHONY: build-repo
build-repo:
	DOCKER_BUILDKIT=1 REPO_SHA=$(REPO_SHA) \
		docker buildx bake --load --progress=plain repo-local
