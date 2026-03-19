# hangouts

AI coding agents sandbox - custom Docker environment for multi-agent development.

## Quick Start

```bash
# 1. 環境変数を設定
cp .env.example .env
# .env にGITHUB_TOKENを記入（オプション — OAuth利用時は不要）

# 2. イメージビルド
make build

# 3. エージェント起動
make claude
make codex
make gemini
make gh
make copilot
make difit
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
| `make claude` | Claude Code を起動 |
| `make codex` | Codex CLI を起動 |
| `make gemini` | Gemini CLI を起動 |
| `make gh ARGS="..."` | GitHub CLI を実行 |
| `make copilot ARGS="..."` | GitHub Copilot CLI を実行 |
| `make difit ARGS="..."` | difit を実行 |
| `make shell` | コンテナ内でbashを起動 |
| `make run CMD="..."` | 任意のコマンドを実行 |
| `make clean` | コンテナ・イメージを削除 |

## Config Sync

ホスト側のエージェント設定をコンテナと双方向で共有する仕組み:

- 各エージェントの設定ディレクトリを **read-write bind mount** でマウント
- コンテナ内での設定変更がホスト側に即反映
- SSH・gitconfigは **read-only** でマウント

### マウント対象

| Path | Mode |
|---|---|
| `~/.claude` | rw |
| `~/.codex` | rw |
| `~/.gemini` | rw |
| `~/.config/gh` | rw |
| `~/.config/github-copilot` | rw |
| `~/.ssh` | ro |
| `~/.gitconfig` | ro |
| `/var/run/docker.sock` | rw |

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
- **SSH/git**: `~/.ssh` と `~/.gitconfig` をread-onlyマウント
- **Docker in Docker**: `/var/run/docker.sock` を常時マウント
