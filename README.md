# hangouts

AI coding agents sandbox - custom Docker environment for multi-agent development.

## Quick Start

```bash
# 1. 環境変数を設定
cp .env.example .env
# .env にGITHUB_TOKENを記入（オプション — OAuth利用時は不要）

# 2. イメージビルド
make build

# 3. エージェント起動（カレントディレクトリが作業対象）
make claude
make codex
make gemini
make gh
make copilot
make difit

# 別ディレクトリを作業対象にする場合
make claude WORKSPACE=/path/to/your/project
```

## Included CLIs

| CLI | Package | Description |
|---|---|---|
| `claude` | native installer | Claude Code |
| `codex` | `@openai/codex` | OpenAI Codex CLI |
| `gemini` | `@google/gemini-cli` | Google Gemini CLI |
| `copilot` | `@github/copilot` | GitHub Copilot CLI |
| `difit` | `difit` | difit |
| `gh` | apt (official) | GitHub CLI |

## Make Targets

| Target | Description |
|---|---|
| `make build` | Dockerイメージをビルド |
| `make prepare` | Claude Code のマウントソース準備（`make claude` で自動実行） |
| `make claude` | Claude Code を起動（YOLO mode） |
| `make codex` | Codex CLI を起動（full-auto mode） |
| `make gemini` | Gemini CLI を起動（YOLO mode） |
| `make gh ARGS="..."` | GitHub CLI を実行 |
| `make copilot ARGS="..."` | GitHub Copilot CLI を実行 |
| `make difit ARGS="..."` | difit を実行 |
| `make shell` | コンテナ内でbashを起動 |
| `make run CMD="..."` | 任意のコマンドを実行 |
| `make clean` | コンテナ・イメージを削除 |

各agentターゲットは `$(ARGS)` で追加引数を渡せる: `make claude ARGS="-p 'do something'"`

### WORKSPACE

デフォルトではカレントディレクトリ (`$PWD`) がコンテナ内の `/workspace` にマウントされる。
別のディレクトリを作業対象にしたい場合は `WORKSPACE` 変数を指定する:

```bash
make claude WORKSPACE=/path/to/your/project
```

## YOLO Mode

各agentはデフォルトで権限確認をスキップするフラグ付きで起動する:

| Agent | フラグ |
|---|---|
| Claude | `--dangerously-skip-permissions` |
| Codex | `--yolo` |
| Gemini | `--yolo` |
| Copilot | `--yolo` |

## Claude Code 同期方式

ホストの `~/.claude` を丸ごとマウントすると auto-update 競合やバージョン不整合でクラッシュするため、
**個別ファイル/ディレクトリの bind mount** で共有すべきものだけを明示的にマウントする。

### マウント対象（Claude Code）

| パス | マウント先 | Mode | 用途 |
|---|---|---|---|
| `~/.claude/.credentials.json` | `/home/agent/.claude/.credentials.json` | ro | OAuth 認証 |
| `~/.claude/settings.json` | `/home/agent/.claude/settings.json` | ro | 設定 |
| `~/.claude/history.jsonl` | `/home/agent/.claude/history.jsonl` | rw | 会話履歴 |
| `~/.claude/projects/` | `/home/agent/.claude/projects` | rw | memory, CLAUDE.md, 会話 |
| `~/.claude/sessions/` | `/home/agent/.claude/sessions` | rw | セッション追跡 |
| `~/.claude/tasks/` | `/home/agent/.claude/tasks` | rw | タスクデータ |
| `~/.claude/plans/` | `/home/agent/.claude/plans` | rw | プラン |
| `~/.claude/todos/` | `/home/agent/.claude/todos` | rw | Todo 状態 |
| `~/.claude/plugins/` | `/home/agent/.claude/plugins` | rw | プラグイン |
| `~/.claude/skills/` | `/home/agent/.claude/skills-host` | ro | スキル定義（staging） |
| `~/.agents/` | `/home/agent/.agents` | ro | skills の symlink 解決先 |
| `.container/claude.json` | `/home/agent/.claude.json` | ro | autoUpdates=false |

### マウントしないもの（コンテナ内 ephemeral）

`debug/`, `cache/`, `telemetry/`, `file-history/`, `shell-snapshots/`, `backups/`, `statsig/`,
`.update.lock` 等 — コンテナ終了時に `--rm` で自動消滅。ホスト側に漏れない。

### Skills の扱い

`~/.claude/skills/` は `skills-host:ro` としてマウントし、entrypoint でコンテナ内にコピーする。
ホスト絶対パスの symlink（コンテナ内で解決不可）は自動除去される。
相対 symlink は `~/.agents` マウントにより正常に解決される。

### Plugins の扱い

`installed_plugins.json` 内の `installPath` がホスト絶対パスのため、
entrypoint で `$HOST_HOME/.claude → /home/agent/.claude` symlink を作成してパスを解決する。
この symlink はコンテナ終了で消滅し、ホスト側に影響しない。

## 他のエージェント設定

| Path | Mode |
|---|---|
| `~/.codex` | rw |
| `~/.gemini` | rw |
| `~/.config/gh` | rw |
| `~/.config/github-copilot` | rw |
| `~/.gitconfig` | ro |
| `/var/run/docker.sock` | rw |

## Git認証

`GITHUB_TOKEN` 環境変数（PAT）を使ったHTTPS認証方式:

- entrypointで `gh auth setup-git` を実行し、gitのcredential helperを自動設定
- SSH鍵のマウントやagent forwarding不要
- `.env` に `GITHUB_TOKEN` を設定するだけで動作

## Push Protection

default branch（main/master）への直 push を二重に防御:

1. **GitHub Branch Protection Ruleset（サーバー側・主防御）** — admin も「Allow for pull requests only」に設定。API 経由の push もブロック
2. **pre-push フック（クライアント側・補助）** — main, master, develop, staging への push をローカルで拒否し、親切なエラーメッセージを表示

feature branch への push は許可される。変更を反映するには PR を作成すること。

```bash
git push origin main        # → 拒否
git push origin feature/x   # → 許可
```

## Architecture

```
docker compose run --rm hangouts claude
```

- **ワークスペース**: bind mountでホスト側コードを直接編集
- **選択的マウント**: 必要なファイル/ディレクトリだけを個別にbind mount
- **使い捨て実行**: `--rm` でマウントされないデータ（debug, cache, telemetry等）はコンテナ破棄で消える
- **二段階 entrypoint**: root フェーズ（symlink作成、skills copy）→ `gosu` で agent ユーザーに降格
- **Git認証**: `GITHUB_TOKEN` + `gh auth setup-git` でHTTPS認証
- **Docker in Docker**: `/var/run/docker.sock` を常時マウント
