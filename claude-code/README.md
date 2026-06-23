# Claude Code — sandboxed

Throwaway container running Anthropic's Claude Code (`claude`) against
whatever directory you launch it from.

## Build

```sh
docker build -t cca-claude-code .
```

## Run

From the project you want the agent to work on:

```sh
docker run -it --rm -v "$(pwd):/workspace" -w /workspace cca-claude-code
```

You'll sign in on first launch. The container is disposable (`--rm`), so each
run starts clean and re-auth is expected.