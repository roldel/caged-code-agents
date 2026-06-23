# Codex CLI — sandboxed

Throwaway container running OpenAI's Codex CLI (`codex`) against whatever
directory you launch it from.

## Build

```sh
docker build -t cca-openai-codex .
```

## Run

From the project you want the agent to work on:

```sh
docker run -it --rm -v "$(pwd):/workspace" -w /workspace cca-openai-codex
```

You'll sign in on first launch. The container is disposable (`--rm`), so each
run starts clean and re-auth is expected.