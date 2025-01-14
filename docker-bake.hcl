// docker-bake.hcl
// -*- mode: hcl -*-


group "default" {
  targets = ["scratch"]
}

group "all" {
  targets = [
    "scratch",
    "alpine",
    "debian"
  ]
}

variable "ALPINE" {
  default = "docker.io/alpine:latest"
}
variable "DEBIAN" {
  default = "docker.io/debian:stable-slim"
}

variable "COMMIT" {
  default = "HEAD"
}
variable "GIT_URL" {
  default = "https://github.com/jart/cosmopolitan.git"
}
variable "PACKAGES" {
  default = join(" ", [
    "git",
    "ca-certificates",
    "curl",
    "make",
    "unzip",
  ])
}
variable "MODE" {
  default = "optlinux"
}
variable "TARGET_NAME" {}
variable "TARGET_PATH" {
  default = "/tool/net/redbean"
}
variable UID {
  default = "1000"
}
variable GID {
  default = "1000"
}
variable USER {
  default = "cosmopolitan"
}
variable GROUP {
  default = "cosmopolitan"
}
variable "REGISTRY_OWNER" {
  default = "local"
}
variable "OUTPUT_DIR" {
  default = "output"
}


// inheritable targets

target "_labels" {
  labels = {
    "build.date"                           = timestamp(),
    "cosmopolitan.mode"                    = MODE,
    "cosmopolitan.target"                  = TARGET_PATH,
    "org.opencontainers.image.created"     = timestamp(),
    "org.opencontainers.image.authors"     = REGISTRY_OWNER,
    "org.opencontainers.image.revision"    = COMMIT,
    "org.opencontainers.image.vendor"      = "Cosmopolitan https://github.com/jart/cosmopolitan",
    "org.opencontainers.image.licenses"    = "ISC",
    "org.opencontainers.image.title"       = basename(TARGET_PATH),
    "org.opencontainers.image.description" = "build-once run-anywhere",
  }
}


target "scratch" {
  inherits = ["_labels", "scratch-final"]
  target   = "final"
  labels = {
    "org.opencontainers.image.title"     = basename(TARGET_PATH),
    "org.opencontainers.image.base.name" = "scratch",
  }
  tags = [createTag(notequal(TARGET_NAME, "") ? TARGET_NAME : basename(TARGET_PATH))]
}
// scratch sub targets
target "scratch-repository" {
  dockerfile = "dockerfiles/Dockerfile.scratch"
  target     = "repository"
  args = {
    DEBIAN   = DEBIAN,
    COMMIT   = COMMIT,
    GIT_URL  = GIT_URL,
    PACKAGES = PACKAGES,
  }
  tags = [createTag("scratch-repository")]
}
target "scratch-compile" {
  dockerfile = "dockerfiles/Dockerfile.scratch"
  target     = "compile"
  contexts = {
    repository = "target:scratch-repository"
  }
  args = {
    MODE        = MODE,
    TARGET_PATH = TARGET_PATH,
  }
  tags = [createTag("scratch-compile")]
}
target "scratch-clean" {
  dockerfile = "dockerfiles/Dockerfile.scratch"
  target     = "clean"
  contexts = {
    compile = "target:scratch-compile"
  }
  args = {
    TARGET_PATH = TARGET_PATH,
    UID         = UID,
    GID         = GID,
    USER        = USER,
    GROUP       = GROUP,
  }
  tags = [createTag("scratch-clean")]
}
target "scratch-final" {
  dockerfile = "dockerfiles/Dockerfile.scratch"
  target     = "final"
  contexts = {
    clean = "target:scratch-clean"
  }
  args = {
    UID  = UID,
    GID  = GID,
    USER = USER,
  }
  tags = [createTag("scratch-final")]
}


target "debian" {
  inherits = ["_labels", "debian-final"]
  target   = "final"
  labels = {
    "org.opencontainers.image.title"     = "${basename(TARGET_PATH)}-debian",
    "org.opencontainers.image.base.name" = DEBIAN,
  }
  tags = [createTag("${notequal(TARGET_NAME, "") ? TARGET_NAME : basename(TARGET_PATH)}-debian")]
}
// debian sub targets
target "debian-repository" {
  dockerfile = "dockerfiles/Dockerfile.debian"
  target     = "repository"
  args = {
    DEBIAN   = DEBIAN,
    COMMIT   = COMMIT,
    GIT_URL  = GIT_URL,
    PACKAGES = PACKAGES,
  }
  tags = [createTag("debian-repository")]
}
target "debian-compile" {
  dockerfile = "dockerfiles/Dockerfile.debian"
  target     = "compile"
  contexts = {
    repository = "target:debian-repository"
  }
  args = {
    MODE        = MODE,
    TARGET_PATH = TARGET_PATH,
  }
  tags = [createTag("debian-compile")]
}
target "debian-clean" {
  dockerfile = "dockerfiles/Dockerfile.debian"
  target     = "clean"
  contexts = {
    compile = "target:debian-compile"
  }
  args = {
    TARGET_PATH = TARGET_PATH,
    UID         = UID,
    GID         = GID,
    USER        = USER,
    GROUP       = GROUP,
  }
  tags = [createTag("debian-clean")]
}
target "debian-final" {
  dockerfile = "dockerfiles/Dockerfile.debian"
  target     = "final"
  contexts = {
    clean = "target:debian-clean"
  }
  args = {
    UID  = UID,
    GID  = GID,
    USER = USER,
  }
  tags = [createTag("debian-final")]
}


target "alpine" {
  inherits = ["_labels", "alpine-final"]
  target   = "final"
  labels = {
    "org.opencontainers.image.title"     = "${basename(TARGET_PATH)}-alpine",
    "org.opencontainers.image.base.name" = ALPINE,
  }
  tags = [createTag("${notequal(TARGET_NAME, "") ? TARGET_NAME : basename(TARGET_PATH)}-alpine")]
}
// alpine sub targets
target "alpine-repository" {
  dockerfile = "dockerfiles/Dockerfile.alpine"
  target     = "repository"
  args = {
    ALPINE   = ALPINE,
    COMMIT   = COMMIT,
    GIT_URL  = GIT_URL,
    PACKAGES = PACKAGES,
  }
  tags = [createTag("alpine-repository")]
}
target "alpine-compile" {
  dockerfile = "dockerfiles/Dockerfile.alpine"
  target     = "compile"
  contexts = {
    repository = "target:alpine-repository"
  }
  args = {
    MODE        = MODE,
    TARGET_PATH = TARGET_PATH,
  }
  tags = [createTag("alpine-compile")]
}
target "alpine-clean" {
  dockerfile = "dockerfiles/Dockerfile.alpine"
  target     = "clean"
  contexts = {
    compile = "target:alpine-compile"
  }
  args = {
    TARGET_PATH = TARGET_PATH,
    UID         = UID,
    GID         = GID,
    USER        = USER,
    GROUP       = GROUP,
  }
  tags = [createTag("alpine-clean")]
}
target "alpine-final" {
  dockerfile = "dockerfiles/Dockerfile.alpine"
  target     = "final"
  contexts = {
    clean = "target:alpine-clean"
  }
  args = {
    UID  = UID,
    GID  = GID,
    USER = USER,
  }
  tags = [createTag("alpine-final")]
}


target "binary-output" {
  output = ["type=local,dest=${OUTPUT_DIR}"]
  contexts = {
    compile = "target:alpine-compile"
  }
  args = {
    TARGET_PATH = TARGET_PATH
  }
  dockerfile-inline = <<-EOT
    FROM compile AS ctx
    FROM scratch
    ARG TARGET_PATH
    COPY --from=ctx "$${TARGET_PATH}" /
  EOT
}
target "repo-output" {
  output = ["type=local,dest=${OUTPUT_DIR}"]
  contexts = {
    repository = "target:alpine-repository"
  }
  dockerfile-inline = <<EOT
    FROM repository as ctx
    FROM scratch
    COPY --from=ctx /cosmopolitan /
  EOT
}


// user-defined functions
function "basename" {
  // extracts the final component of a given file path
  params = [given]
  result = element(split("/", given), length(split("/", given)) - 1)
}

function "shortSHA" {
  // trim the given string, keep the first 6 characters
  params = [given]
  result = substr(given, 0, 6)
}

function "createTag" {
  // create tag: commitSHA -> [name]:12ab34 or HEAD -> [name]:MODE
  params = [name]
  result = join(":", [name, notequal("HEAD", COMMIT) ? "${MODE}-${shortSHA(COMMIT)}" : MODE])
}
