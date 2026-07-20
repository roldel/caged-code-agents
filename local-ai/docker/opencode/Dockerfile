# OpenCode — sandboxed, Ollama-backed, runtime model selection
FROM python:slim-bookworm

# Installer + jq (config templating) need these; slim image ships almost nothing
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Non-root user owning the workspace
RUN useradd -m -s /bin/bash agent && \
    mkdir -p /workspace && \
    chown -R agent:agent /workspace

USER agent
WORKDIR /workspace

# Install the OpenCode CLI (installs to $HOME/.opencode/bin by default)
RUN curl -fsSL https://opencode.ai/install | bash
ENV PATH="/home/agent/.opencode/bin:${PATH}"

# Entrypoint builds opencode.json at container start from OPENCODE_MODELS
COPY --chown=agent:agent entrypoint.sh /home/agent/entrypoint.sh
RUN chmod +x /home/agent/entrypoint.sh

ENTRYPOINT ["/home/agent/entrypoint.sh"]
CMD []