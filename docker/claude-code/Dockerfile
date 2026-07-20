# Claude Code — minimal sandboxed image
FROM python:slim-bookworm

ARG USER_ID
ARG GROUP_ID
 
RUN test -n "${USER_ID}" && test -n "${GROUP_ID}" || \
    { echo >&2 "ERROR: build with --build-arg USER_ID=\$(id -u) --build-arg GROUP_ID=\$(id -g)"; exit 1; }

# Installer + agent need these; the slim image ships almost nothing
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Non-root user matching the host UID/GID (fail-loud args above)
RUN (getent group ${GROUP_ID} || groupadd -g ${GROUP_ID} agent) && \
    useradd -m -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash agent
 
USER agent

# Install the Claude Code CLI
RUN curl -fsSL https://claude.ai/install.sh | bash

ENV PATH="/home/agent/.local/bin:${PATH}"

# Sign in interactively on first run; nothing baked into the image
CMD ["claude"]