# caged-code-agents

**Throwaway Docker sandboxes for terminal coding agents.**

Run a coding agent against your real project files — while it stays locked in a container that can only see one bind-mounted directory. Cloud CLIs (Claude Code, Codex, Grok Build) and a local Ollama-backed option (OpenCode) are all included.

---

## Why?

Terminal coding agents are powerful, but they also have a wide surface: they can read files, run commands, and reach the network. Sometimes you want that power **without** giving the agent free rein over your whole machine.

These images give you:

| | |
|---|---|
| **Isolation** | Only the directory you mount is visible to the agent |
| **Minimal images** | Debian-based Python slim images with just what each CLI needs |
| **Throwaway runs** | `--rm` containers — no leftover sandbox state |
| **Real files** | The agent edits your actual project via a bind mount |

---

## Agents

### Cloud-backed

| Agent | Directory | Image tag | CLI |
|-------|-----------|-----------|-----|
| [Claude Code](claude-code/) | `claude-code/` | `cca-claude-code` | `claude` |
| [Codex CLI](openai-codex/) | `openai-codex/` | `cca-openai-codex` | `codex` |
| [Grok Build](grok-build/) | `grok-build/` | `cca-grok-build` | `grok` |

Sign in interactively on first launch. Containers are disposable, so re-auth each run is expected.

### Local (Ollama)

| Agent | Directory | Image tag | CLI |
|-------|-----------|-----------|-----|
| [OpenCode](local/opencode/) | `local/opencode/` | `cca-opencode` | `opencode` |

Talks to Ollama on the host. Models are selected at `docker run` time — no image rebuild to switch or add models. Model IDs must already exist in your host's Ollama (`ollama list`); the container only registers them with OpenCode.

Each agent has its own Dockerfile and a short README with build/run notes.

---

## Quick start

### Cloud agent (example: Claude Code)

**1. Build** the image:

```sh
cd claude-code
docker build -t cca-claude-code .
```

**2. Run** it from the project you want the agent to work on:

```sh
docker run -it --rm \
  -v "$(pwd):/workspace" \
  -w /workspace \
  cca-claude-code
```

**3. Sign in** when prompted.

Same pattern for Codex and Grok — swap the directory and image tag:

```sh
# Codex CLI
cd openai-codex && docker build -t cca-openai-codex .
docker run -it --rm -v "$(pwd):/workspace" -w /workspace cca-openai-codex

# Grok Build
cd grok-build && docker build -t cca-grok-build .
docker run -it --rm -v "$(pwd):/workspace" -w /workspace cca-grok-build
```

### Local agent (OpenCode + Ollama)

Requires [Ollama](https://ollama.com/) running on the host with the models you want already pulled.

```sh
cd local/opencode
docker build -t cca-opencode .

# Default model list (see local/opencode/README.md)
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

`--add-host=host.docker.internal:host-gateway` lets the container reach Ollama on the host. Override the URL with `OLLAMA_BASE_URL` if needed.

---

## Notes

- **Cloud auth is interactive.** Credentials are not baked into the images. Each fresh cloud container needs a sign-in.
- **Local models live on the host.** OpenCode registers model IDs only; pull them with Ollama yourself first.
- **Scope is the mount.** Anything outside the bind-mounted path is not available to the agent on the host filesystem.
- **Docker required.** Build and run with a local Docker (or compatible) daemon.

Pick an agent directory, build, and launch from the repo you want edited. That's the whole loop.
