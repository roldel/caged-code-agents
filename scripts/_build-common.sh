#!/bin/bash
# Shared build logic for scripts/build-docker-images.sh,
# scripts/build-podman-images.sh, and scripts/build-local-ai-images.sh.
# Not meant to be run directly.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# dir: leaf directory a README's build command would cd into (used as the
#   default Dockerfile location and, for simple leaves, the build context).
# tag: image tag to apply.
# dockerfile/context: overridden for local-ai/opencode, which builds from its
#   parent directory so both engines can share one entrypoint.sh (see
#   local-ai/opencode/*/README.md).
build() {
  local engine="$1" dir="$2" tag="$3"
  local dockerfile="${4:-$dir/Dockerfile}" context="${5:-$dir}"
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

# Cloud agents only. OpenCode is build_local_ai_images.
build_cloud_images() {
  local engine="$1"
  if [ "$engine" = "docker" ]; then
    build docker "$root/docker/claude-code" "cca-claude-code"
    build docker "$root/docker/openai-codex" "cca-openai-codex"
    build docker "$root/docker/grok-build" "cca-grok-build"
  elif [ "$engine" = "podman" ]; then
    build podman "$root/podman/claude-code" "localhost/cca-claude-code:latest"
    build podman "$root/podman/openai-codex" "localhost/cca-openai-codex:latest"
    build podman "$root/podman/grok-build" "localhost/cca-grok-build:latest"
  else
    echo >&2 "ERROR: unknown engine '$engine'"
    exit 1
  fi
  echo "==> [$engine] cloud images rebuilt"
}

# OpenCode on every engine that is actually installed. A missing engine is
# skipped; a failed build of an installed engine still aborts (set -e).
build_local_ai_images() {
  local built=0
  if command -v docker >/dev/null 2>&1; then
    build docker "$root/local-ai/opencode/docker" "cca-opencode" \
      "$root/local-ai/opencode/docker/Dockerfile" "$root/local-ai/opencode"
    built=1
  else
    echo "==> [docker] not on PATH, skipping local OpenCode image"
  fi
  if command -v podman >/dev/null 2>&1; then
    build podman "$root/local-ai/opencode/podman" "localhost/cca-opencode:latest" \
      "$root/local-ai/opencode/podman/Dockerfile" "$root/local-ai/opencode"
    built=1
  else
    echo "==> [podman] not on PATH, skipping local OpenCode image"
  fi
  if [ "$built" -eq 0 ]; then
    echo >&2 "ERROR: neither docker nor podman is on PATH"
    exit 1
  fi
  echo "==> [local-ai] images rebuilt for installed engines"
}
