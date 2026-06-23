# Grok Build — sandboxed

Throwaway container running xAI's Grok Build (`grok`) against whatever
directory you launch it from.

## Build

```sh
docker build -t cca-grok-build .
```

## Run

From the project you want the agent to work on:

```sh
docker run -it --rm -v "$(pwd):/workspace" -w /workspace cca-grok-build
```

You'll sign in on first launch. The container is disposable (`--rm`), so each
run starts clean and re-auth is expected.