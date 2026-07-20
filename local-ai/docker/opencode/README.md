# OpenCode Build — sandboxed, runtime model selection

Ollama-backed OpenCode sandbox. Models are chosen at `docker run` time via
environment variables — no rebuild needed to switch or add models.

## Build

docker build -t cca-opencode .

## Run

Single model, defaults (`ornith:9b`):

    docker run -it --rm \
      --add-host=host.docker.internal:host-gateway \
      -v "$(pwd):/workspace" \
      -w /workspace \
      cca-opencode

Multiple models available in the same session (switch with `/model` in the TUI):

    docker run -it --rm \
    --add-host=host.docker.internal:host-gateway \
    -e OPENCODE_MODELS="ornith:32k,gpt-oss:20b-32k" \
    -e OPENCODE_DEFAULT_MODEL="ornith:32k" \
    -v "$(pwd):/workspace" \
    -w /workspace \
    cca-opencode

Model IDs must already exist in your host's Ollama (`ollama list`) — this just registers them with OpenCode, it doesn't pull them.
