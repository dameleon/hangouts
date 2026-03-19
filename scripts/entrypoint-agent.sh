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

# ── Project path mapping ──────────────────────────────────────────────
# HOST_WORKSPACE_PATH が設定されている場合、コンテナの -workspace プロジェクトディレクトリを
# ホストパスベースのディレクトリにシンボリックリンクし、ホスト/コンテナ間で
# 会話履歴・メモリ・設定を共有する
if [ -n "${HOST_WORKSPACE_PATH:-}" ]; then
    claude_projects="/home/agent/.claude/projects"
    # パスを Claude Code のディレクトリ名形式に変換（英数字・ハイフン以外→ハイフン）
    target_name=$(printf '%s' "$HOST_WORKSPACE_PATH" | sed 's/[^a-zA-Z0-9-]/-/g')
    target_dir="${claude_projects}/${target_name}"
    workspace_dir="${claude_projects}/-workspace"

    mkdir -p "$target_dir"

    # -workspace が実ディレクトリの場合、リネームして退避（手動で判断できるようにする）
    if [ -d "$workspace_dir" ] && [ ! -L "$workspace_dir" ]; then
        backup_dir="${claude_projects}/-workspace.bak.$(date +%Y%m%d%H%M%S)"
        mv "$workspace_dir" "$backup_dir"
        echo "[hangouts] Backed up existing -workspace to ${backup_dir}" >&2
    fi

    # 古いシンボリックリンクが別のターゲットを指している場合は削除
    if [ -L "$workspace_dir" ]; then
        current_target=$(readlink "$workspace_dir")
        if [ "$current_target" != "$target_dir" ]; then
            rm -f "$workspace_dir"
        fi
    fi

    # シンボリックリンク作成
    if [ ! -e "$workspace_dir" ]; then
        ln -s "$target_dir" "$workspace_dir"
    fi
fi

exec "$@"
