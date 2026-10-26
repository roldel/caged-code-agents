#!/bin/bash
# Shared build logic for scripts/build-docker-images.sh and
# scripts/build-podman-images.sh. Not meant to be run directly.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# dir: leaf directory a README's build command would cd into (used as the
#   default Dockerfile location and, for simple leaves, the build context).
# tag: image tag to apply.
# dockerfile/context: overridden for local-ai/opencode, which builds from its
#   parent directory so both engines can share one entrypoint.sh (see
#   local-ai/opencode/*/README.md).
build() {
  local engine="$1" dir="$2" tag="$3" dockerfile="${4:-$dir/Dockerfile}" context="${5:-$dir}"
  echo "==> [$engine] building $tag (--no-cache)"
  if [ "$engine" = "docker" ]; then
    docker build --no-cache \
      --build-arg USER_ID="$(id -u)" \
      --build-arg GROUP_ID="$(id -g)" \
      -f "$dockerfile" -t "$tag" "$context"
  else
    podman build --no-cache -f "$dockerfile" -t "$tag" "$context"
  fi
}

build_all_images() {
  local engine="$1"
  if [ "$engine" = "docker" ]; then
    build docker "$root/docker/claude-code" "cca-claude-code"
    build docker "$root/docker/openai-codex" "cca-openai-codex"
    build docker "$root/docker/grok-build" "cca-grok-build"
    build docker "$root/local-ai/opencode/docker" "cca-opencode" \
      "$root/local-ai/opencode/docker/Dockerfile" "$root/local-ai/opencode"
  else
    build podman "$root/podman/claude-code" "localhost/cca-claude-code:latest"
    build podman "$root/podman/openai-codex" "localhost/cca-openai-codex:latest"
    build podman "$root/podman/grok-build" "localhost/cca-grok-build:latest"
    build podman "$root/local-ai/opencode/podman" "localhost/cca-opencode:latest" \
      "$root/local-ai/opencode/podman/Dockerfile" "$root/local-ai/opencode"
  fi
  echo "==> [$engine] all images rebuilt"
}
