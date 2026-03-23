#!/usr/bin/env bash
set -euo pipefail

exec gosu agent /usr/local/share/hangouts/scripts/entrypoint-agent.sh "$@"
