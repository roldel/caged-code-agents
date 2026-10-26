# caged-code-agents

**Throwaway sandboxes for terminal coding agents — built for either Docker or Podman.**

Run a coding agent against your real project files — while it stays locked in a container that can only see one bind-mounted directory. Cloud CLIs (Claude Code, Codex, Grok Build) and a local Ollama-backed option (OpenCode) are all included, each available as both a Docker build and a Podman build.

## Quick access

Build and run commands live in each leaf README. Pick an agent and engine:

### Cloud-backed

Sign in interactively on first launch. Containers are disposable, so re-auth each run is expected.

| Agent | Docker | Podman |
|-------|--------|--------|
| Claude Code | [README](docker/claude-code/README.md) | [README](podman/claude-code/README.md) |
| Codex CLI | [README](docker/openai-codex/README.md) | [README](podman/openai-codex/README.md) |
| Grok Build | [README](docker/grok-build/README.md) | [README](podman/grok-build/README.md) |

### Local (Ollama)

Requires [Ollama](https://ollama.com/) on the host with models already pulled (`ollama list`). The container only registers model IDs with OpenCode; pick models at run time — no image rebuild.

| Agent | Docker | Podman |
|-------|--------|--------|
| OpenCode | [README](local-ai/opencode/docker/README.md) | [README](local-ai/opencode/podman/README.md) |

New here? Read on below. Returning? Use the table above and go.

---

| | |
|---|---|
| [Why?](#why) | Why sandbox coding agents at all |
| [Project structure](#project-structure) | How the repo is laid out |
| [Permission strategy](#permission-strategy) | Docker vs Podman ownership model |
| [Quick start](#quick-start) | One worked example of the build/run loop |
| [Notes](#notes) | Auth, models, and mount scope |
| [Rebuilding images](#rebuilding-images) | Refresh every image for an engine in one command |

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
    entrypoint.sh
    docker/
    podman/

scripts/                Repo-level helpers: build-docker-images.sh, build-podman-images.sh
```

Each leaf directory is self-contained: a `Dockerfile` and a short `README.md` with the exact build/run commands for that agent and engine. The one exception is `local-ai/opencode/`, where the Docker and Podman builds share a single `entrypoint.sh` (one level up from both leaf directories) that discovers installed Ollama models, lets you pick which to expose, and builds OpenCode's provider config at container start — so its leaf READMEs build with `-f <engine>/Dockerfile` from `local-ai/opencode/` instead of `cd`-ing straight into the leaf.

Cloud agents are grouped by engine first (`docker/`, `podman/`) since each is just one CLI per engine. Local agents are grouped by agent first (`local-ai/opencode/`) since a local agent's Docker and Podman builds share the same Ollama-facing logic — and it keeps room to add more local agents later without the engine split scattering them.

---

## Permission strategy

We map your Linux user into the container so the agent runs as you on the bind-mounted project — files it creates or edits stay owned by you on the host.

Docker and Podman both aim at that, but they wire it up differently.

**Docker binds your user at image build. Podman binds your user at container run.**

- **Docker** cannot remap your host UID/GID onto the in-container `agent` user when you start the container. So the image is built with your IDs baked in (`--build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g)`; required, or the build fails). That matches the user who built the image. If another host user runs the same image later, the container still starts, but ownership on the mount may not match them — they need their own build.
- **Podman** can map the user who starts the container onto a fixed in-image `agent` (`uid=1000`/`gid=1000`) at run time via `--userns=keep-id:uid=1000,gid=1000`. One image works for any host user; that flag must always be present on `podman run`.

Same goal either way. Choose the engine that fits how you build and share images.

---

## Quick start

One example so the loop is obvious. For every other agent/engine, use [Quick access](#quick-access).

### Example: Claude Code on Docker

```sh
cd docker/claude-code
docker build \
  --build-arg USER_ID=$(id -u) \
  --build-arg GROUP_ID=$(id -g) \
  -t cca-claude-code .

# From the project you want the agent to edit:
docker run -it --rm \
  -v "$(pwd):/workspace" \
  -w /workspace \
  cca-claude-code
```

Same idea everywhere else: `cd` into the leaf directory, build the image, then `run` with your project bind-mounted at `/workspace`. Podman builds use fixed tags under `localhost/…:latest`, `--userns=keep-id:uid=1000,gid=1000`, and usually `--pull=never`. Local OpenCode also needs host Ollama reachability (`--add-host=host.docker.internal:host-gateway`); see its leaf README for model selection — an interactive picker by default, or `OPENCODE_MODELS`/`OPENCODE_DEFAULT_MODEL` for scripted runs. OpenCode's build step differs slightly: `cd local-ai/opencode` (not the leaf) and pass `-f docker/Dockerfile` or `-f podman/Dockerfile`, since it shares `entrypoint.sh` across both engines.

---

## Notes

- **Cloud auth is interactive.** Credentials are not baked into the images. Each fresh cloud container needs a sign-in.
- **Local models live on the host.** OpenCode registers model IDs only; pull them with Ollama yourself first.
- **Scope is the mount.** Anything outside the bind-mounted path is not available to the agent on the host filesystem.
- **Docker or Podman required.** Build and run with whichever engine's directory you pick — see [Permission strategy](#permission-strategy) for how each one keeps the container's non-root user in sync with yours.
- **Base images are intentionally unpinned.** Every Dockerfile floats on `python:slim-bookworm` rather than a pinned version, so a `--no-cache` rebuild always picks up current Debian security patches. None of these images run Python application code — it's just the lightweight Debian base each CLI installer runs on top of — so the usual breaking-change risk of floating tags doesn't really apply here. Pin a specific tag yourself if you need fully reproducible builds.

## Rebuilding images

`scripts/build-docker-images.sh` and `scripts/build-podman-images.sh` each rebuild every image for their engine with `--no-cache`, so a fresh CLI install (or base image patch) doesn't require `cd`-ing into each leaf directory and remembering its build command. They're separate scripts (sharing an internal `scripts/_build-common.sh`) so you only pay the rebuild time for the engine you actually use:

```sh
scripts/build-docker-images.sh
scripts/build-podman-images.sh
```

Pick an agent under [Quick access](#quick-access), open its README, build, and launch from the repo you want edited. That's the whole loop.
