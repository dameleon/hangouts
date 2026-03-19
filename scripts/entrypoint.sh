#!/usr/bin/env bash
set -euo pipefail

# Host ~/.gitconfig is mounted read-only — create a writable copy for container use
export GIT_CONFIG_GLOBAL=/home/agent/.gitconfig-local
cp /home/agent/.gitconfig "$GIT_CONFIG_GLOBAL" 2>/dev/null || touch "$GIT_CONFIG_GLOBAL"

# Set global git hooks path (pre-push blocks direct push to protected branches)
git config --file "$GIT_CONFIG_GLOBAL" core.hooksPath /usr/local/share/hangouts/hooks

# Configure git to use GitHub CLI for HTTPS authentication
# Host .git/config keeps SSH URLs for host-side SSH key auth;
# insteadOf transparently rewrites them to HTTPS inside the container
if command -v gh &>/dev/null && [ -n "${GITHUB_TOKEN:-}" ]; then
    gh auth setup-git 2>/dev/null || true
    git config --file "$GIT_CONFIG_GLOBAL" url."https://github.com/".insteadOf "git@github.com:"
    git config --file "$GIT_CONFIG_GLOBAL" --add url."https://github.com/".insteadOf "ssh://git@github.com/"
fi

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
