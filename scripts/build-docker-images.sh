#!/bin/bash
# Rebuilds the cloud Docker images (Claude Code, Codex CLI, Grok Build)
# from scratch (--no-cache). OpenCode is scripts/build-local-ai-images.sh.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_build-common.sh"

build_cloud_images docker
