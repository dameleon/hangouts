#!/usr/bin/env bash
set -euo pipefail

# Configure git to use GitHub CLI for HTTPS authentication
if command -v gh &>/dev/null && [ -n "${GITHUB_TOKEN:-}" ]; then
    gh auth setup-git 2>/dev/null
fi

exec "$@"
