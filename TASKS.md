# Tasks

## Phase 0: プロジェクト基盤
- [x] `.gitignore` 作成
- [x] `.dockerignore` 作成
- [x] `.env.example` 作成

## Phase 1: Dockerfile
- [x] `Dockerfile` 作成
  - ベース: `node:22-bookworm-slim`
  - システム依存: git, curl, jq, less, openssh-client
  - npm CLI一括インストール: claude, codex, gemini, copilot, difit
  - gh CLI: apt公式リポジトリから
  - scripts コピー + entrypoint設定

## Phase 2: docker-compose.yml
- [x] `docker-compose.yml` 作成
  - RW bind mountで設定ディレクトリを双方向共有
  - docker.sock常時マウント
  - 環境変数はGITHUB_TOKENのみ

## Phase 3: Makefile
- [x] `Makefile` 作成

## Phase 4: ドキュメント・テスト
- [x] `TASKS.md` 作成
- [x] `README.md` 更新
- [ ] ビルド＆動作確認

## Phase 5: YOLO mode + Git認証改善
- [x] Makefileに各agentのYOLOフラグ追加（claude, codex, gemini）
- [x] SSH直接マウントを廃止、PAT（GITHUB_TOKEN）+ `gh auth setup-git` 方式に変更
- [x] entrypoint.shに `gh auth setup-git` 追加
- [x] README.md更新（YOLO mode、Git認証説明）
- [ ] 動作確認
- [ ] コンテナ専用SSH鍵の生成（将来検討）
