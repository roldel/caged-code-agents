#!/bin/bash
set -euo pipefail

# Comma-separated list of Ollama model IDs to expose, e.g.:
#   OPENCODE_MODELS="ornith:latest,gpt-oss:20b,gemma4:12b-mlx"
# Tags must match `ollama list` exactly, colon included.
# Leave unset to be prompted interactively with the models Ollama already has.
: "${OPENCODE_MODELS:=}"

# Which model is preselected on launch. Defaults to the first in the list.
: "${OPENCODE_DEFAULT_MODEL:=}"

# Override if Ollama isn't reachable at the default docker host alias
: "${OLLAMA_BASE_URL:=http://host.docker.internal:11434/v1}"

if [ -z "$OPENCODE_MODELS" ]; then
  if [ ! -t 0 ]; then
    echo "entrypoint: OPENCODE_MODELS is not set and there's no interactive terminal to prompt on." >&2
    echo "entrypoint: run with -it, or pass -e OPENCODE_MODELS=\"model1,model2\"." >&2
    exit 1
  fi

  # Native Ollama API lives one level up from the OpenAI-compatible /v1 path.
  # Strip a trailing slash first so "…/v1/" strips down to "…", not "…/v1".
  ollama_api_root="${OLLAMA_BASE_URL%/}"
  ollama_api_root="${ollama_api_root%/v1}"

  tags_json=$(curl -fsS "${ollama_api_root}/api/tags") || {
    echo "entrypoint: couldn't reach Ollama at ${ollama_api_root}/api/tags" >&2
    echo "entrypoint: make sure Ollama is running on the host, or pass -e OPENCODE_MODELS=\"model1,model2\" to skip discovery." >&2
    exit 1
  }

  mapfile -t available < <(printf '%s' "$tags_json" | jq -r '.models[].name')

  if [ "${#available[@]}" -eq 0 ]; then
    echo "entrypoint: Ollama has no models pulled yet. Run 'ollama pull <model>' on the host first." >&2
    exit 1
  fi

  # Parameter count, quantization and disk size are already in /api/tags.
  mapfile -t summaries < <(printf '%s' "$tags_json" | jq -r '
    .models[]
    | [
        (.details.parameter_size // "?"),
        (.details.quantization_level // "?"),
        ((.size // 0) / 1073741824 * 10 | round / 10 | tostring)
      ]
    | @tsv
  ')

  # Split the tab-separated summaries back into parallel arrays so column
  # widths can be measured before anything is printed.
  row_params=() row_quant=() row_size=()
  for i in "${!available[@]}"; do
    IFS=$'\t' read -r param_size quant size_gb <<< "${summaries[$i]}"
    row_params+=("$param_size")
    row_quant+=("$quant")
    row_size+=("${size_gb}GB")
  done

  # Width of each column = widest value in it (header label included)
  col_width() {
    local max=${#1}
    shift
    local s
    for s in "$@"; do
      [ "${#s}" -gt "$max" ] && max="${#s}"
    done
    echo "$max"
  }
  count="${#available[@]}"
  idx_width=$((${#count} + 1))
  name_width=$(col_width "MODEL" "${available[@]}")
  params_width=$(col_width "PARAMS" "${row_params[@]}")
  quant_width=$(col_width "QUANT" "${row_quant[@]}")
  size_width=$(col_width "SIZE" "${row_size[@]}")

  echo "Available Ollama models:" >&2
  printf '  %-*s  %-*s  %-*s  %-*s  %-*s\n' \
    "$idx_width" "#" "$name_width" "MODEL" "$params_width" "PARAMS" \
    "$quant_width" "QUANT" "$size_width" "SIZE" >&2
  for i in "${!available[@]}"; do
    printf '  %-*s  %-*s  %-*s  %-*s  %-*s\n' \
      "$idx_width" "$((i + 1))." "$name_width" "${available[$i]}" \
      "$params_width" "${row_params[$i]}" "$quant_width" "${row_quant[$i]}" \
      "$size_width" "${row_size[$i]}" >&2
  done

  read -rp "Select models to expose (comma-separated numbers, 'a' for all) [a]: " selection

  selected=()
  trimmed_selection="$(printf '%s' "$selection" | tr -d '[:space:]')"
  if [ -z "$trimmed_selection" ] || [ "${trimmed_selection,,}" = "a" ] || [ "${trimmed_selection,,}" = "all" ]; then
    # Registering a model with OpenCode doesn't load it — Ollama only loads
    # on first actual use — so exposing everything by default costs nothing.
    selected=("${available[@]}")
  else
    IFS=',' read -ra raw_choices <<< "$selection"
    for choice in "${raw_choices[@]}"; do
      choice="$(printf '%s' "$choice" | tr -d '[:space:]')"
      [ -z "$choice" ] && continue
      if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#available[@]}" ]; then
        echo "entrypoint: '$choice' isn't one of the listed numbers" >&2
        exit 1
      fi
      model="${available[$((choice - 1))]}"
      already_selected=0
      for existing in "${selected[@]:-}"; do
        [ "$existing" = "$model" ] && already_selected=1
      done
      [ "$already_selected" -eq 0 ] && selected+=("$model")
    done
  fi

  if [ "${#selected[@]}" -eq 0 ]; then
    echo "entrypoint: no models selected" >&2
    exit 1
  fi

  if [ "${#selected[@]}" -eq 1 ]; then
    OPENCODE_DEFAULT_MODEL="${selected[0]}"
  else
    echo "Selected models:" >&2
    for i in "${!selected[@]}"; do
      printf '  %d) %s\n' "$((i + 1))" "${selected[$i]}" >&2
    done
    read -rp "Default model number [1]: " default_idx
    default_idx="${default_idx:-1}"
    if ! [[ "$default_idx" =~ ^[0-9]+$ ]] || [ "$default_idx" -lt 1 ] || [ "$default_idx" -gt "${#selected[@]}" ]; then
      echo "entrypoint: '$default_idx' isn't one of the listed numbers" >&2
      exit 1
    fi
    OPENCODE_DEFAULT_MODEL="${selected[$((default_idx - 1))]}"
  fi

  OPENCODE_MODELS="$(IFS=,; echo "${selected[*]}")"
fi

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
