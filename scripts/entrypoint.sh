#!/usr/bin/env bash
set -euo pipefail

# Configure git to use GitHub CLI for HTTPS authentication
# Note: ~/.gitconfig is mounted read-only, so write to GIT_CONFIG_GLOBAL instead
if command -v gh &>/dev/null && [ -n "${GITHUB_TOKEN:-}" ]; then
    export GIT_CONFIG_GLOBAL=/home/agent/.gitconfig-local
    cp /home/agent/.gitconfig "$GIT_CONFIG_GLOBAL" 2>/dev/null || true
    gh auth setup-git 2>/dev/null || true
fi

exec "$@"
