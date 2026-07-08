# Claude Code — sandboxed

## Build

```sh
docker build -t cca-claude-code .
```

## Run

From the project you want the agent to work on:

```sh
docker run -it --rm -v "$(pwd):/workspace" -w /workspace cca-claude-code
```