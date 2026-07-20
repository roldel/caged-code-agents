# Codex CLI — minimal sandboxed image
FROM python:3.14-slim-bookworm

# Installer + agent need these; gawk is required by the Codex installer
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    gawk \
    && rm -rf /var/lib/apt/lists/*

# Non-root user owning the workspace
RUN useradd -m -s /bin/bash agent && \
    mkdir -p /workspace && \
    chown -R agent:agent /workspace

USER agent
WORKDIR /workspace

# Install the Codex CLI (non-interactive installer, pipes to sh not bash)
RUN curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh

ENV PATH="/home/agent/.local/bin:${PATH}"

# Sign in interactively on first run; nothing baked into the image
CMD ["codex"]