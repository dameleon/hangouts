#!/usr/bin/env bash
set -euo pipefail

# Start D-Bus session bus and gnome-keyring for credential storage (e.g. copilot)
if command -v dbus-run-session &>/dev/null && command -v gnome-keyring-daemon &>/dev/null; then
    # Wrap exec in dbus-run-session so all child processes share the bus
    if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
        exec dbus-run-session -- "$0" "$@" 2>/dev/null
    fi
    # Unlock gnome-keyring with an empty password
    echo "" | gnome-keyring-daemon --unlock --components=secrets 2>/dev/null || true
fi

# Configure git to use GitHub CLI for HTTPS authentication
# Note: ~/.gitconfig is mounted read-only, so write to GIT_CONFIG_GLOBAL instead
if command -v gh &>/dev/null && [ -n "${GITHUB_TOKEN:-}" ]; then
    export GIT_CONFIG_GLOBAL=/home/agent/.gitconfig-local
    cp /home/agent/.gitconfig "$GIT_CONFIG_GLOBAL" 2>/dev/null || true
    gh auth setup-git 2>/dev/null || true
fi

exec "$@"
