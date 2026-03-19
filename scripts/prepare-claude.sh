#!/usr/bin/env bash
set -euo pipefail

HOST_DIR="${HOME}/.claude"
HOST_JSON="${HOME}/.claude.json"

# ── ファイル型マウントソースの存在保証 ──
# Docker は存在しないファイルソースをディレクトリとして作成するため
[ -f "$HOST_DIR/.credentials.json" ] || touch "$HOST_DIR/.credentials.json"
[ -f "$HOST_DIR/settings.json" ]     || echo '{}' > "$HOST_DIR/settings.json"
[ -f "$HOST_DIR/history.jsonl" ]     || touch "$HOST_DIR/history.jsonl"

# ── ディレクトリ型マウントソースの存在保証 ──
mkdir -p "$HOST_DIR/projects" \
         "$HOST_DIR/sessions" \
         "$HOST_DIR/tasks" \
         "$HOST_DIR/plans" \
         "$HOST_DIR/todos" \
         "$HOST_DIR/skills" \
         "$HOST_DIR/plugins" \
         "${HOME}/.agents"

# ── claude.json 変換（autoUpdates=false）──
mkdir -p .container
if [ -f "$HOST_JSON" ]; then
    jq '.autoUpdates = false' "$HOST_JSON" > .container/claude.json
else
    echo '{"autoUpdates":false}' > .container/claude.json
fi
