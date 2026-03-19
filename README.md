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
| `claude` | `@anthropic-ai/claude-code` | Claude Code |
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

## YOLO Mode

各agentはデフォルトで権限確認をスキップするフラグ付きで起動する:

| Agent | フラグ |
|---|---|
| Claude | `--dangerously-skip-permissions` |
| Codex | `--yolo` |
| Gemini | `--yolo` |
| Copilot | `--yolo` |

## Config Sync

ホスト側のエージェント設定をコンテナと双方向で共有する仕組み:

- 各エージェントの設定ディレクトリを **read-write bind mount** でマウント
- コンテナ内での設定変更がホスト側に即反映
- gitconfigは **read-only** でマウント

### マウント対象

| Path | Mode |
|---|---|
| `~/.claude` | rw |
| `~/.claude.json` | rw |
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
docker run --rm -it \
  -v ~/.claude:/root/.claude \
  -v "${PWD}:/workspace" \
  -w /workspace \
  -e GITHUB_TOKEN \
  hangouts claude
```

- **ワークスペース**: bind mountでホスト側コードを直接編集
- **設定共有**: RW bind mountでホストとコンテナ間で双方向同期
- **使い捨て実行**: `--rm` でワークスペース・設定外の変更はコンテナ破棄で消える
- **Git認証**: `GITHUB_TOKEN` + `gh auth setup-git` でHTTPS認証
- **Docker in Docker**: `/var/run/docker.sock` を常時マウント
