# Claude Code — minimal sandboxed image
FROM python:slim-bookworm

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Non-root user owning the workspace
RUN groupadd -g 1000 agent && \
    useradd -m -u 1000 -g 1000 -s /bin/bash agent

USER agent

# Install the Claude Code CLI
RUN curl -fsSL https://claude.ai/install.sh | bash

ENV PATH="/home/agent/.local/bin:${PATH}"

# Sign in interactively on first run; nothing baked into the image
CMD ["claude"]
