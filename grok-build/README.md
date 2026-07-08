# Grok Build — sandboxed

## Build

```sh
docker build -t cca-grok-build .
```

## Run

From the project you want the agent to work on:

```sh
docker run -it --rm -v "$(pwd):/workspace" -w /workspace cca-grok-build
```