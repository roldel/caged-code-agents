#!/bin/bash
# Rebuilds local OpenCode images from scratch (--no-cache) for every engine
# on PATH. Skips an engine that is not installed. Fails if neither docker nor
# podman is on PATH, or if a build for an installed engine fails.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_build-common.sh"

build_local_ai_images
