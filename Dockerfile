FROM node:22-bookworm-slim

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    jq \
    less \
    openssh-client \
    gnupg \
    dbus \
    gnome-keyring \
    libsecret-1-0 \
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

# Claude Code via native installer (recommended over npm)
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && ln -s /root/.local/bin/claude /usr/local/bin/claude

# npm-based CLIs
RUN npm install -g \
    @openai/codex \
    @google/gemini-cli \
    @github/copilot \
    difit

# Non-root user (required for claude --dangerously-skip-permissions)
RUN useradd -m -s /bin/bash agent
RUN mkdir -p /home/agent/.config /home/agent/.local/share/keyrings \
    && chown -R agent:agent /home/agent

# Scripts
COPY scripts/ /usr/local/share/hangouts/scripts/
RUN chmod +x /usr/local/share/hangouts/scripts/*.sh

# Git hooks (pre-push: block direct push to protected branches)
COPY scripts/hooks/ /usr/local/share/hangouts/hooks/
RUN chmod +x /usr/local/share/hangouts/hooks/*

USER agent
WORKDIR /workspace

ENTRYPOINT ["/usr/local/share/hangouts/scripts/entrypoint.sh"]
CMD ["bash"]
