# Claude Code — sandboxed

## Build

```sh
podman build -t cca-claude-code .
```

## Run

From the project you want the agent to work on:

```sh
podman run -it --rm \
  --userns=keep-id:uid=1000,gid=1000 \
  -v "$(pwd):/workspace" \
  -w /workspace \
  cca-claude-code
```
