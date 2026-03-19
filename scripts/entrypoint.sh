#!/usr/bin/env bash
set -euo pipefail

# ── Root phase ───────────────────────────────────────────────────

# HOST_HOME symlink: plugins の installPath（ホスト絶対パス）をコンテナ内で解決
if [ -n "${HOST_HOME:-}" ]; then
    host_claude="${HOST_HOME}/.claude"
    if [ ! -e "$host_claude" ]; then
        mkdir -p "$(dirname "$HOST_HOME")"
        ln -sfn /home/agent/.claude "$host_claude"
    fi
fi

# Skills: read-only staging からコピーし、壊れた絶対 symlink を除去
SKILLS_HOST="/home/agent/.claude/skills-host"
SKILLS_DIR="/home/agent/.claude/skills"
if [ -d "$SKILLS_HOST" ]; then
    cp -a "$SKILLS_HOST/." "$SKILLS_DIR/" 2>/dev/null || true
    # 壊れた symlink を除去（絶対パスで解決不能なもの）
    find "$SKILLS_DIR" -maxdepth 1 -type l ! -exec test -e {} \; -delete 2>/dev/null || true
    chown -R agent:agent "$SKILLS_DIR"
fi

# ── Drop to agent ────────────────────────────────────────────────
exec gosu agent /usr/local/share/hangouts/scripts/entrypoint-agent.sh "$@"
