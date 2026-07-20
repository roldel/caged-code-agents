# Codex CLI — sandboxed

## Build

```sh
docker build \
  --build-arg USER_ID=$(id -u) \
  --build-arg GROUP_ID=$(id -g) \
  -t cca-openai-codex .
```

## Run

From the project you want the agent to work on:

```sh
docker run -it --rm \
  -v "$(pwd):/workspace" \
  -w /workspace \
  cca-openai-codex
```