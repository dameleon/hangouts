FROM node:22-bookworm-slim

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    curl \
    jq \
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
ADD scripts/entrypoint.sh /usr/local/share/hangouts/scripts/entrypoint.sh
ADD scripts/entrypoint-agent.sh /usr/local/share/hangouts/scripts/entrypoint-agent.sh
# Git hooks (pre-push: block direct push to protected branches)
ADD scripts/hooks/pre-push /usr/local/share/hangouts/hooks/pre-push

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

# .claude ディレクトリ構造を事前作成（agent 所有）
# bind mount はこの上に載る。マウントされないディレクトリは ephemeral として残る
RUN mkdir -p /home/agent/.claude \
             /home/agent/.claude/projects \
             /home/agent/.claude/sessions \
             /home/agent/.claude/tasks \
             /home/agent/.claude/plans \
             /home/agent/.claude/todos \
             /home/agent/.claude/skills \
             /home/agent/.claude/plugins \
             /home/agent/.agents \
             /home/agent/.config \
             /home/agent/.local/share/keyrings

# ファイルマウントターゲット（Docker がディレクトリとして作成するのを防ぐ）
RUN touch /home/agent/.claude/.credentials.json \
          /home/agent/.claude/settings.json \
          /home/agent/.claude/history.jsonl \
          /home/agent/.claude.json

RUN curl -fsSL https://claude.ai/install.sh | bash

# entrypoint は root で開始（HOST_HOME symlink + skills copy 後に gosu で agent に降格）
USER root

WORKDIR /workspace

ENTRYPOINT ["/usr/local/share/hangouts/scripts/entrypoint.sh"]
CMD ["bash"]
