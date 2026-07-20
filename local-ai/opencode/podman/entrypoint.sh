#!/bin/bash
set -euo pipefail

# Comma-separated list of Ollama model IDs to expose, e.g.:
#   OPENCODE_MODELS="ornith:latest,gpt-oss:20b,gemma4:12b-mlx"
# Tags must match `ollama list` exactly, colon included.
: "${OPENCODE_MODELS:=ornith:9b}"

# Which model is preselected on launch. Defaults to the first in the list.
: "${OPENCODE_DEFAULT_MODEL:=}"

# Override if Ollama isn't reachable at the default docker host alias
: "${OLLAMA_BASE_URL:=http://host.docker.internal:11434/v1}"

# Build { "<model-id>": { "name": "<model-id>", "tools": true }, ... } in a
# single jq pass. Splitting/trimming/encoding all happen inside jq, so model
# IDs are never round-tripped through `jq -R` twice (which was baking literal
# quotes into the keys).
models_json=$(printf '%s' "$OPENCODE_MODELS" \
  | jq -R 'split(",")
           | map(gsub("^\\s+|\\s+$"; ""))
           | map(select(length > 0))
           | map({(.): {name: ., tools: true}})
           | add')

if [ "$(printf '%s' "$models_json" | jq 'length')" -eq 0 ]; then
  echo "entrypoint: OPENCODE_MODELS resolved to an empty list" >&2
  exit 1
fi

# First key in the map (insertion order preserved by keys_unsorted)
default_model="${OPENCODE_DEFAULT_MODEL:-$(printf '%s' "$models_json" | jq -r 'keys_unsorted[0]')}"

mkdir -p "$HOME/.config/opencode"

jq -n \
  --argjson models "$models_json" \
  --arg baseURL "$OLLAMA_BASE_URL" \
  --arg default "ollama/$default_model" \
  '{
    "$schema": "https://opencode.ai/config.json",
    "provider": {
      "ollama": {
        "npm": "@ai-sdk/openai-compatible",
        "name": "Ollama (host)",
        "options": {
          "baseURL": $baseURL,
          "apiKey": "ollama"
        },
        "models": $models
      }
    },
    "model": $default
  }' > "$HOME/.config/opencode/opencode.json"

exec opencode "$@"