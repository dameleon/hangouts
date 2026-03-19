#!/usr/bin/env bash
set -euo pipefail

# Configure git to use GitHub CLI for HTTPS authentication
# Note: ~/.gitconfig is mounted read-only, so write to GIT_CONFIG_GLOBAL instead
if command -v gh &>/dev/null && [ -n "${GITHUB_TOKEN:-}" ]; then
    export GIT_CONFIG_GLOBAL=/home/agent/.gitconfig-local
    cp /home/agent/.gitconfig "$GIT_CONFIG_GLOBAL" 2>/dev/null || true
    gh auth setup-git 2>/dev/null || true
    # Transparently rewrite SSH URLs to HTTPS so PAT auth works
    # without modifying the workspace's .git/config (host-shared)
    git config --file "$GIT_CONFIG_GLOBAL" url."https://github.com/".insteadOf "ssh://git@github.com/"
    git config --file "$GIT_CONFIG_GLOBAL" url."https://github.com/".insteadOf "git@github.com:"
fi

# Set global git hooks path (pre-push blocks direct push to protected branches)
git config --file "${GIT_CONFIG_GLOBAL:-/home/agent/.gitconfig-local}" core.hooksPath /usr/local/share/hangouts/hooks

# Start D-Bus + gnome-keyring only for commands that need credential storage (e.g. copilot)
# dbus-run-session breaks TTY signal handling, so we only use it when necessary
case "${1:-}" in
    copilot)
        if command -v dbus-run-session &>/dev/null && command -v gnome-keyring-daemon &>/dev/null; then
            exec dbus-run-session -- bash -c '
                echo "" | gnome-keyring-daemon --unlock --components=secrets >/dev/null 2>&1 || true
                exec "$@"
            ' -- "$@"
        fi
        ;;
esac

exec "$@"
