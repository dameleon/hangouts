FROM node:22-bookworm-slim

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    curl \
    less \
    openssh-client \
    gnupg \
    dbus \
    gnome-keyring \
    libsecret-1-0 \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# gh CLI via official apt repository
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Scripts
ADD scripts/entrypoint.sh /opt/hangouts/entrypoint.sh
ADD scripts/hooks/pre-push /opt/hangouts/hooks/pre-push

# npm-based CLIs
RUN npm install -g \
    @openai/codex \
    @google/gemini-cli \
    @github/copilot \
    difit

# Non-root user (required for claude --dangerously-skip-permissions)
RUN useradd -m -s /bin/bash agent

USER agent
ENV PATH=$PATH:/home/agent/.local/bin
ENV TERM=xterm-256color

RUN mkdir -p /home/agent/.config \
             /home/agent/.local/share/keyrings

RUN curl -fsSL https://claude.ai/install.sh | bash

USER root

ENTRYPOINT ["/opt/hangouts/entrypoint.sh"]
CMD ["bash"]
