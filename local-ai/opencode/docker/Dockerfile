# OpenCode — sandboxed, Ollama-backed, runtime model selection
FROM python:slim-bookworm

ARG USER_ID
ARG GROUP_ID

RUN test -n "${USER_ID}" && test -n "${GROUP_ID}" || \
    { echo >&2 "ERROR: build with --build-arg USER_ID=\$(id -u) --build-arg GROUP_ID=\$(id -g)"; exit 1; }

# Installer + jq (config templating) need these; slim image ships almost nothing
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Non-root user matching the host UID/GID (fail-loud args above)
RUN (getent group ${GROUP_ID} || groupadd -g ${GROUP_ID} agent) && \
    useradd -m -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash agent

USER agent

# Install the OpenCode CLI (installs to $HOME/.opencode/bin by default)
RUN curl -fsSL https://opencode.ai/install | bash
ENV PATH="/home/agent/.opencode/bin:${PATH}"

# Entrypoint builds opencode.json at container start from OPENCODE_MODELS
COPY --chown=${USER_ID}:${GROUP_ID} entrypoint.sh /home/agent/entrypoint.sh
RUN chmod +x /home/agent/entrypoint.sh

ENTRYPOINT ["/home/agent/entrypoint.sh"]
CMD []
