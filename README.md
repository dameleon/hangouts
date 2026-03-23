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

> **注意**: `WORKSPACE` は絶対パスで指定すること。`docker compose` を直接使う場合も同様。

## YOLO Mode

各agentはデフォルトで権限確認をスキップするフラグ付きで起動する:

| Agent | フラグ |
|---|---|
| Claude | `--dangerously-skip-permissions` |
| Codex | `--yolo` |
| Gemini | `--yolo` |
| Copilot | `--yolo` |

## Claude Code 同期方式

ホストの `~/.claude` を直接マウントすると auto-update 競合やバージョン不整合でクラッシュするため、
`.container/` ディレクトリをステージング領域として使い、ホスト `~/.claude` とは分離する。

### 仕組み

1. `.container/.claude/` にエージェント設定を配置（ホスト `~/.claude` からコピーまたは手動構成）
2. `docker-compose.yml` で `.container/.claude` → `/home/agent/.claude` に丸ごと bind mount
3. コンテナ内の変更は `.container/.claude/` に反映されるが、ホスト `~/.claude` には影響しない

### マウント一覧（Claude Code）

| ホスト側 | コンテナ側 | 用途 |
|---|---|---|
| `.container/.claude/` | `/home/agent/.claude` | Claude Code 設定・データ全般 |
| `.container/.claude.json` | `/home/agent/.claude.json` | トップレベル設定（autoUpdates=false 等） |

### 注意事項

- コンテナ内で生成される `debug/`, `cache/`, `telemetry/` 等も `.container/.claude/` に残る
- `.container/` は `.gitignore` 済み
- ホスト `~/.claude` を汚さない代わりに、認証情報やセッション等は `.container/.claude/` に手動で配置する必要がある

## 他のエージェント設定

| ホスト側 | コンテナ側 | Mode |
|---|---|---|
| `.container/.codex` | `/home/agent/.codex` | rw |
| `.container/.gemini` | `/home/agent/.gemini` | rw |
| `.container/.config/gh` | `/home/agent/.config/gh` | rw |
| `.container/.config/github-copilot` | `/home/agent/.config/github-copilot` | rw |
| `/var/run/docker.sock` | `/var/run/docker.sock` | rw |

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
- **ステージングマウント**: `.container/` を各エージェント設定の bind mount 元として使用
- **使い捨て実行**: `--rm` でコンテナ破棄。`.container/` 以外のデータは消える
- **権限降格**: root で起動 → `gosu` で即座に agent ユーザーに降格
- **Git認証**: `GITHUB_TOKEN` + `gh auth setup-git` でHTTPS認証
- **Docker in Docker**: `/var/run/docker.sock` を常時マウント
