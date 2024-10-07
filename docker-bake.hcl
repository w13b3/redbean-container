# docker-bake.hcl

# # # groups

group "default" {
  targets = ["scratch"]
}


# # # variables
# # docs.docker.com/build/bake/reference/#variable
# # set an environment variable to change the default variables

# # tag variables
variable "REGISTRY_OWNER" {
  default = "local"
}
variable "REPO_SHA" {
  default = ""
}
variable "SHORT_SHA" {
  default = "${shortSHA(REPO_SHA)}"
}

# # build arguments
variable "BIN_DIR" {
  default = "/usr/local/bin"
}
variable "MODE" {
  default = "optlinux"
}
variable "ALPINE" {
  # alpine:3.19.1
  default = "alpine@sha256:c5b1261d6d3e43071626931fc004f70149baeba2c8ec672bd4f27761f8e1ad6b"
}
variable "DEBIAN" {
  # debian:bookworm-20240408-slim
  default = "debian@sha256:3d5df92588469a4c503adbead0e4129ef3f88e223954011c2169073897547cac"
}


# # image metadata
variable "LABELS" {
  default = {
    "dev.redbean.mode"     = "${MODE}",
    "dev.redbean.licenses" = "ISC,MIT,BSD-2,BSD-3,zlib;https://redbean.dev/#legal",
    "com.github.cosmopolitan.rev" = equal("", REPO_SHA) ? timestamp() : "${REPO_SHA}"
  }
}


# # # user-defined functions

function "shortSHA" {
  # trim the given string, keep the first 6 characters
  params = [given]
  result = substr(given, 0, 6)
}


# # # inhertable targets

target "_annotations" {
  # https://specs.opencontainers.org/image-spec/annotations/
  annotations = [
    "org.opencontainers.image.created=${timestamp()}",
    "org.opencontainers.image.authors=${REGISTRY_OWNER}",
    "org.opencontainers.image.url=http://github.com/${REGISTRY_OWNER}",
    "org.opencontainers.image.revision=${REPO_SHA}",
    "org.opencontainers.image.vendor=Cosmopolitan https://github.com/jart/cosmopolitan",
    "org.opencontainers.image.licenses=ISC,MIT,BSD-2,BSD-3,zlib",
    "org.opencontainers.image.title=redbean",
    "org.opencontainers.image.description=single-file distributable web server",
  ]
}


# # # targets
# # sub step images

target "repo" {
  context    = "."
  dockerfile = "dockerfiles/Dockerfile.repo"
  contexts = {
    packages = "packages"  # used to copy ./packages/apt.txt into the image
    debian = "docker-image://${DEBIAN}"
  }
  args = {
    REPO_SHA = "${REPO_SHA}"  # default ""
  }
}

target "repo-local" {
  inherits = ["repo"]
  tags = [
    equal("", REPO_SHA) ? "repo:latest" : "repo:${SHORT_SHA}",
  ]
}

target "binaries" {
  context    = "."
  dockerfile = "dockerfiles/Dockerfile.binaries"
  contexts = {
    repo = "target:repo"
  }
  args = {
    MODE = "${MODE}"  # default "optlinux"
  }
}

target "binaries-local" {
  inherits = ["binaries"]
  tags = [
    equal("", REPO_SHA) ? "binaries:latest" : "binaries:${SHORT_SHA}",
  ]
}

# # final images

target "scratch" {
  inherits   = ["_annotations"]
  context    = "."
  dockerfile = "dockerfiles/Dockerfile.scratch"
  contexts = {
    binaries = "target:binaries"
  }
  args = {
    BIN_DIR = "${BIN_DIR}"  # default "/usr/local/bin"
  }
  tags = concat([
    "redbean:${MODE}",
    "ghcr.io/${REGISTRY_OWNER}/redbean:${MODE}",
    # if available; also add tags with short sha 
    ], equal("", REPO_SHA) ? [] : [
    "redbean:${MODE}-${SHORT_SHA}",
    "ghcr.io/${REGISTRY_OWNER}/redbean:${MODE}-${SHORT_SHA}",
  ])
  labels = merge(LABELS, {
    "container.base.image" : "scratch"
  })
}

target "alpine" {
  inherits   = ["_annotations"]
  context    = "."
  dockerfile = "dockerfiles/Dockerfile.alpine"
  contexts = {
    // alpine:3.19.1
    alpine   = "docker-image://${ALPINE}"
    binaries = "target:binaries"
  }
  args = {
    BIN_DIR = "${BIN_DIR}"  # default "/usr/local/bin"
  }
  tags = concat([
    "redbean:${MODE}-alpine",
    "ghcr.io/${REGISTRY_OWNER}/redbean:${MODE}-alpine",
    # if available; also add tags with short sha 
    ], equal("", REPO_SHA) ? [] : [
    "redbean:${MODE}-alpine-${SHORT_SHA}",
    "ghcr.io/${REGISTRY_OWNER}/redbean:${MODE}-alpine-${SHORT_SHA}",
  ])
  labels = merge(LABELS, {
    "container.base.image" : "${ALPINE}"
  })
}
