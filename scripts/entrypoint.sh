#!/usr/bin/env bash
set -euo pipefail

# Drop privileges to agent user if running as root
if [ "$(id -u)" = "0" ]; then
    exec gosu agent "$0" "$@"
fi

export GIT_CONFIG_GLOBAL=/home/agent/.gitconfig-local
touch "$GIT_CONFIG_GLOBAL"

# Set global git hooks path (pre-push blocks direct push to protected branches)
git config --file "$GIT_CONFIG_GLOBAL" core.hooksPath /opt/hangouts/hooks

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
