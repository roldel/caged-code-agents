# Grok Build — minimal sandboxed image
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

# Install the Grok Build CLI
RUN curl -fsSL https://x.ai/cli/install.sh | bash

ENV PATH="/home/agent/.grok/bin:${PATH}"

# Sign in interactively on first run; nothing baked into the image
CMD ["grok"]