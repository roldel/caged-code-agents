# caged-code-agents

**Throwaway sandboxes for terminal coding agents — built for either Docker or Podman.**

Run a coding agent against your real project files — while it stays locked in a container that can only see one bind-mounted directory. Cloud CLIs (Claude Code, Codex, Grok Build) and a local Ollama-backed option (OpenCode) are all included, each available as both a Docker build and a Podman build.

---

## Why?

Terminal coding agents are powerful, but they also have a wide surface: they can read files, run commands, and reach the network. Sometimes you want that power **without** giving the agent free rein over your whole machine.

These images give you:

| | |
|---|---|
| **Isolation** | Only the directory you mount is visible to the agent |
| **Minimal images** | Debian-based Python slim images with just what each CLI needs |
| **Throwaway runs** | `--rm` containers — no leftover sandbox state |
| **Real files** | The agent edits your actual project via a bind mount, owned by you on the host |
| **Choice of engine** | Every agent ships a Docker build and a Podman build |

---

## Project structure

```
docker/                 Docker builds — cloud-backed agents
  claude-code/
  openai-codex/
  grok-build/

podman/                 Podman builds — same cloud-backed agents
  claude-code/
  openai-codex/
  grok-build/

local-ai/               Ollama-backed local agents, grouped by agent then engine
  opencode/
    docker/
    podman/
```

Each leaf directory is self-contained: a `Dockerfile` and a short `README.md` with the exact build/run commands for that agent and engine. `local-ai/opencode/*/` additionally ships an `entrypoint.sh` that builds OpenCode's provider config from environment variables at container start.

Cloud agents are grouped by engine first (`docker/`, `podman/`) since each is just one CLI per engine. Local agents are grouped by agent first (`local-ai/opencode/`) since a local agent's Docker and Podman builds share the same Ollama-facing logic — and it keeps room to add more local agents later without the engine split scattering them.

---

## Permission strategy

Both engines end up with the same result — the agent runs as a non-root user, and files it touches on your bind-mounted project stay owned by you on the host — but they get there differently:

- **Docker (`docker/`, `local-ai/opencode/docker/`)** — the image is built per host user. `docker build` takes `--build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g)`, and the Dockerfile fails loudly if either is missing. The in-container `agent` user is created with those exact IDs, so it matches your host user 1:1. Trade-off: the image is tied to whoever built it — a different host user needs their own build.
- **Podman (`podman/`, `local-ai/opencode/podman/`)** — the image bakes in a fixed `agent` user at `uid=1000`/`gid=1000`, no build-args needed. At run time, `--userns=keep-id:uid=1000,gid=1000` tells Podman's rootless user namespace to map *your* invoking host user onto that in-container UID/GID. Trade-off: one image works for any host user, but it always relies on that run-time flag being present.

Pick whichever fits how you build/distribute images; both are wired up identically otherwise.

---

## Agents

### Cloud-backed

| Agent | Docker | Podman | Image tag | CLI |
|-------|--------|--------|-----------|-----|
| Claude Code | `docker/claude-code/` | `podman/claude-code/` | `cca-claude-code` | `claude` |
| Codex CLI | `docker/openai-codex/` | `podman/openai-codex/` | `cca-openai-codex` | `codex` |
| Grok Build | `docker/grok-build/` | `podman/grok-build/` | `cca-grok-build` | `grok` |

Sign in interactively on first launch. Containers are disposable, so re-auth each run is expected.

### Local (Ollama)

| Agent | Docker | Podman | Image tag | CLI |
|-------|--------|--------|-----------|-----|
| OpenCode | `local-ai/opencode/docker/` | `local-ai/opencode/podman/` | `cca-opencode` | `opencode` |

Talks to Ollama on the host. Models are selected at container-run time — no image rebuild to switch or add models. Model IDs must already exist in your host's Ollama (`ollama list`); the container only registers them with OpenCode.

---

## Quick start

### Cloud agent, Docker (example: Claude Code)

```sh
cd docker/claude-code
docker build \
  --build-arg USER_ID=$(id -u) \
  --build-arg GROUP_ID=$(id -g) \
  -t cca-claude-code .

docker run -it --rm \
  -v "$(pwd):/workspace" \
  -w /workspace \
  cca-claude-code
```

Same pattern for Codex and Grok — swap the directory and image tag (`docker/openai-codex` → `cca-openai-codex`, `docker/grok-build` → `cca-grok-build`).

### Cloud agent, Podman (example: Claude Code)

```sh
cd podman/claude-code
podman build -t cca-claude-code .

podman run -it --rm \
  --userns=keep-id:uid=1000,gid=1000 \
  -v "$(pwd):/workspace" \
  -w /workspace \
  cca-claude-code
```

Same pattern for Codex and Grok — swap the directory and image tag (`podman/openai-codex` → `cca-openai-codex`, `podman/grok-build` → `cca-grok-build`).

Sign in when prompted, on either engine.

### Local agent (OpenCode + Ollama)

Requires [Ollama](https://ollama.com/) running on the host with the models you want already pulled.

**Docker:**

```sh
cd local-ai/opencode/docker
docker build \
  --build-arg USER_ID=$(id -u) \
  --build-arg GROUP_ID=$(id -g) \
  -t cca-opencode .

# Default model (ornith:9b)
docker run -it --rm \
  --add-host=host.docker.internal:host-gateway \
  -v "$(pwd):/workspace" \
  -w /workspace \
  cca-opencode

# Or pick models at runtime (switch with /model in the TUI)
docker run -it --rm \
  --add-host=host.docker.internal:host-gateway \
  -e OPENCODE_MODELS="ornith:32k,gpt-oss:20b-32k" \
  -e OPENCODE_DEFAULT_MODEL="ornith:32k" \
  -v "$(pwd):/workspace" \
  -w /workspace \
  cca-opencode
```

**Podman:**

```sh
cd local-ai/opencode/podman
podman build -t cca-opencode .

# Default model (ornith:9b)
podman run -it --rm \
  --userns=keep-id:uid=1000,gid=1000 \
  --add-host=host.docker.internal:host-gateway \
  -v "$(pwd):/workspace" \
  -w /workspace \
  cca-opencode

# Or pick models at runtime (switch with /model in the TUI)
podman run -it --rm \
  --userns=keep-id:uid=1000,gid=1000 \
  --add-host=host.docker.internal:host-gateway \
  -e OPENCODE_MODELS="ornith:32k,gpt-oss:20b-32k" \
  -e OPENCODE_DEFAULT_MODEL="ornith:32k" \
  -v "$(pwd):/workspace" \
  -w /workspace \
  cca-opencode
```

`--add-host=host.docker.internal:host-gateway` lets the container reach Ollama on the host, on both engines. Override the URL with `OLLAMA_BASE_URL` if needed.

---

## Notes

- **Cloud auth is interactive.** Credentials are not baked into the images. Each fresh cloud container needs a sign-in.
- **Local models live on the host.** OpenCode registers model IDs only; pull them with Ollama yourself first.
- **Scope is the mount.** Anything outside the bind-mounted path is not available to the agent on the host filesystem.
- **Docker or Podman required.** Build and run with whichever engine's directory you pick — see [Permission strategy](#permission-strategy) for how each one keeps the container's non-root user in sync with yours.

Pick an agent directory under `docker/`, `podman/`, or `local-ai/`, build, and launch from the repo you want edited. That's the whole loop.
