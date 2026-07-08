# Codex CLI — sandboxed

## Build

```sh
docker build -t cca-openai-codex .
```

## Run

From the project you want the agent to work on:

```sh
docker run -it --rm -v "$(pwd):/workspace" -w /workspace cca-openai-codex
```