# Grok Build — minimal sandboxed image
FROM python:3.14-slim-bookworm

# Installer + agent need these; the slim image ships almost nothing
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Non-root user owning the workspace
RUN useradd -m -s /bin/bash agent && \
    mkdir -p /workspace && \
    chown -R agent:agent /workspace

USER agent
WORKDIR /workspace

# Install the Grok Build CLI
RUN curl -fsSL https://x.ai/cli/install.sh | bash

ENV PATH="/home/agent/.grok/bin:${PATH}"

# Sign in interactively on first run; nothing baked into the image
CMD ["grok"]