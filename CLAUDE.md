# CLAUDE.md

このリポジトリは、Claude Code 構成のテンプレートと `dev-team` プラグインの配布元です。
共通ルール（言語・自律性・報告形式）は claude.ai 個人設定と `~/.claude/CLAUDE.md` に置き、ここには書きません。

## 委任ルール

- **すべてのリポジトリ検索とテスト実行は Haiku 5.5 サブエージェント（search / grep / audit）に委任し、メインコンテキストを小さく保つ。**
- サブエージェントは `dev-team` プラグイン（`plugins/dev-team/agents/`）が提供する。このリポジトリでは開発中の版を使うため `claude --plugin-dir plugins/dev-team` で起動する（マーケットプレイス版を同時に有効にすると名前が衝突するので、settings.json では有効化しない）。使えない場合は Explore を `model: haiku` で代用する。
- 重大な判断とマージ前のサインオフは `advisor`（Opus 5.5）に依頼する。

## 正本（Single Source of Truth）

| 内容 | 正本 | 同期が必要なもの |
|---|---|---|
| サブエージェント | `plugins/dev-team/agents/*.md` | なし（`scripts/install.sh --with-agents` がコピーする） |
| 導入先リポジトリの CLAUDE.md / settings.json | `plugins/dev-team/templates/` | `skills/init/SKILL.md` の埋め込み（`bash scripts/sync-skill.sh` で更新、validate.sh が照合） |
| ユーザーレベル CLAUDE.md | `user-level/CLAUDE.md` | `cloud/setup-script.sh` のヒアドキュメント（validate.sh が照合） |
| Projects のプロジェクト指示 | `projects/project-instructions.md` | なし（16,000 文字以内を validate.sh が確認） |

## 変更時のルール

- プラグインの内容（agents / skills / templates）を変えたら `plugins/dev-team/.claude-plugin/plugin.json` の `version` を上げる。上げないと、導入済みの利用者に更新が届かない。
- 変更後は `bash scripts/validate.sh` を実行し、Claude Code が使える環境では `claude plugin validate .` も実行する。
- 作業ブランチで変更し、draft PR を作成する。
