# OpenCode Build — sandboxed, runtime model selection (Podman)

Ollama-backed OpenCode sandbox. No rebuild needed to switch or add models.

## Build

`entrypoint.sh` is shared with the Docker build and lives one level up, so
build from `local-ai/opencode/` with `-f` pointing at this leaf's Dockerfile:

    cd local-ai/opencode
    podman build -f podman/Dockerfile -t localhost/cca-opencode:latest .

## Run

    podman run -it --rm \
      --pull=never \
      --userns=keep-id:uid=1000,gid=1000 \
      --add-host=host.docker.internal:host-gateway \
      -v "$(pwd):/workspace" \
      -w /workspace \
      localhost/cca-opencode:latest

On start, the container asks your host's Ollama for its installed models
(`GET /api/tags`) and prompts you to pick which ones to expose, then which of
those should be the default:

    Available Ollama models:
      #   MODEL           PARAMS  QUANT   SIZE
      1.  ornith:9b       9.4B    Q4_K_M  5.3GB
      2.  gpt-oss:20b     20.9B   MXFP4   13.3GB
      3.  gemma4:12b-mlx  12.2B   Q4_0    7.5GB
    Select models to expose (comma-separated numbers, 'a' for all) [a]: 1,3
    Selected models:
      1) ornith:9b
      2) gpt-oss:20b
    Default model number [1]: 2

Press Enter (or type `a`/`all`) to expose every installed model instead of
picking numbers — registering a model with OpenCode doesn't load it, Ollama
only loads on first actual use, so there's no cost to exposing everything.

Columns are aligned to whatever's actually installed — all rows are gathered
before anything is printed, so column widths fit the widest value rather than
a guessed fixed size. All four columns come straight from a single
`/api/tags` call, so the listing is instant regardless of how many models are
installed.

Context window isn't shown here: Ollama's actual context length is a runtime
setting (its own default, or the `OLLAMA_CONTEXT_LENGTH` slider in the
desktop app / env var) that's re-negotiated per request rather than a fixed
model property — adjust it live in Ollama itself rather than by picking a
differently-tagged model here. Model IDs must already exist in your host's
Ollama (`ollama list`) — this just registers them with OpenCode, it doesn't
pull them.

### Non-interactive / scripted runs

Pass `OPENCODE_MODELS` to skip the prompt entirely (useful for CI or wrapper
scripts). `OPENCODE_DEFAULT_MODEL` defaults to the first entry if omitted:

    podman run -it --rm \
      --pull=never \
      --userns=keep-id:uid=1000,gid=1000 \
      --add-host=host.docker.internal:host-gateway \
      -e OPENCODE_MODELS="ornith:32k,gpt-oss:20b-32k" \
      -e OPENCODE_DEFAULT_MODEL="ornith:32k" \
      -v "$(pwd):/workspace" \
      -w /workspace \
      localhost/cca-opencode:latest
