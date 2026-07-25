# Codex CLI — sandboxed

## Build

```sh
podman build -t localhost/cca-openai-codex:latest .
```

## Run

From the project you want the agent to work on:

```sh
podman run -it --rm \
  --pull=never \
  --userns=keep-id:uid=1000,gid=1000 \
  -v "$(pwd):/workspace" \
  -w /workspace \
  localhost/cca-openai-codex:latest
```
