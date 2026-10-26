#!/bin/bash
# Rebuilds every Podman image in this repo from scratch (--no-cache).
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_build-common.sh"

build_all_images podman
