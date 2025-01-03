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
variable "TARGET_PATH" {
    default = "/tool/net/redbean"
}
variable "TARGET_NAME" {
    default = "${filename(TARGET_PATH)}"
}
variable "MODE" {
  default = "optlinux"
}
variable "ALPINE" {
  # alpine:3.21.0
  default = "alpine@sha256:21dc6063fd678b478f57c0e13f47560d0ea4eeba26dfc947b2a4f81f686b9f45"
}
variable "DEBIAN" {
  # debian:bookworm-20241223-slim
  default = "debian@sha256:b877a1a3fdf02469440f1768cf69c9771338a875b7add5e80c45b756c92ac20a"
}

# # output arguments
variable "OUTPUT_DIR" {
  default = "output"
}


# # # user-defined functions

function "shortSHA" {
  # trim the given string, keep the first 6 characters
  params = [given]
  result = substr(given, 0, 6)
}
function "filename" {
  # extracts the final component of a given file path
  params = [given]
  result = element(split("/", given), length(split("/", given)) - 1)
}


# # # inheritable targets

target "_annotations" {
  # https://specs.opencontainers.org/image-spec/annotations/
  annotations = [
    "org.opencontainers.image.created=${timestamp()}",
    "org.opencontainers.image.authors=${REGISTRY_OWNER}",
    "org.opencontainers.image.revision=${REPO_SHA}",
    "org.opencontainers.image.vendor=Cosmopolitan https://github.com/jart/cosmopolitan",
    "org.opencontainers.image.licenses=ISC",
    "org.opencontainers.image.title=${TARGET_NAME}",
    "org.opencontainers.image.description=build-once run-anywhere",
  ]
}

target "_labels" {
  labels = {
    "build.date" = timestamp(),
    "cosmopolitan.commit" = equal("", REPO_SHA) ? "HEAD" : REPO_SHA,
    "cosmopolitan.mode" = MODE,
    "cosmopolitan.target" = TARGET_PATH
  }
}

# # # targets
# # sub step images

target "repo" {
  context    = "."
  dockerfile = "dockerfiles/Dockerfile.repo"
  contexts = {
    debian = "docker-image://${DEBIAN}"
  }
  args = {
    REPO_SHA = REPO_SHA  # default ""
  }
}

target "repo-local" {
  inherits = ["repo", "_labels"]
  tags = [
    equal("", REPO_SHA) ? "repo:latest" : "repo:${SHORT_SHA}",
  ]
}

target "compile" {
  context    = "."
  dockerfile = "dockerfiles/Dockerfile.compile"
  contexts = {
    repo = "target:repo"
  }
  args = {
    MODE = MODE,  # default "optlinux"
    TARGET_NAME = TARGET_NAME,  # default redbean
    TARGET_PATH = TARGET_PATH,  # default "/tool/net/redbean"
  }
}

target "compile-local" {
  inherits = ["compile", "_labels"]
  tags = [
    equal("", REPO_SHA) ? "compile:latest" : "compile:${SHORT_SHA}",
  ]
}

# # final images

target "scratch" {
  inherits   = ["_annotations", "_labels"]
  context    = "."
  dockerfile = "dockerfiles/Dockerfile.scratch"
  contexts = {
    compile = "target:compile"
  }
  args = {
    BIN_DIR = BIN_DIR,  # default "/usr/local/bin"
    TARGET_NAME = TARGET_NAME,  # default redbean
  }
  tags = equal("", REPO_SHA) ? [
    "${TARGET_NAME}:${MODE}",
    "ghcr.io/${REGISTRY_OWNER}/${TARGET_NAME}:${MODE}",
  ] : [
    "${TARGET_NAME}:${MODE}-${SHORT_SHA}",
    "ghcr.io/${REGISTRY_OWNER}/${TARGET_NAME}:${MODE}-${SHORT_SHA}",
  ]
}

target "alpine" {
  inherits   = ["_annotations", "_labels"]
  context    = "."
  dockerfile = "dockerfiles/Dockerfile.alpine"
  contexts = {
    alpine  = "docker-image://${ALPINE}"
    compile = "target:compile"
  }
  args = {
    BIN_DIR = BIN_DIR,  # default "/usr/local/bin"
    TARGET_NAME = TARGET_NAME,  # default redbean
  }
  tags = equal("", REPO_SHA) ? [
    "${TARGET_NAME}:${MODE}-alpine",
    "ghcr.io/${REGISTRY_OWNER}/${TARGET_NAME}:${MODE}-alpine",
  ] : [
    "${TARGET_NAME}:${MODE}-alpine-${SHORT_SHA}",
    "ghcr.io/${REGISTRY_OWNER}/${TARGET_NAME}:${MODE}-alpine-${SHORT_SHA}",
  ]
}

# # output files

target "repo-output" {
  contexts = {
    context = "target:repo"
  }
  dockerfile-inline = <<EOT
    FROM scratch
    COPY --from=context /cosmopolitan /
  EOT
  output = equal("", REPO_SHA) ? [
    "type=local,dest=${OUTPUT_DIR}/cosmopolitan"
  ] : [
    "type=local,dest=${OUTPUT_DIR}-${SHORT_SHA}/cosmopolitan"
  ]
}

target "binary-output" {
  contexts = {
    context = "target:compile"
  }
  args = {
    TARGET_NAME = TARGET_NAME,  # default redbean
  }
  dockerfile-inline = <<EOT
    FROM scratch
    ARG TARGET_NAME
    COPY --from=context "/usr/local/bin/${TARGET_NAME}" /
  EOT
  output = equal("", REPO_SHA) ? [
    "type=local,dest=${OUTPUT_DIR}"
  ] : [
    "type=local,dest=${OUTPUT_DIR}-${SHORT_SHA}"
  ]
}
