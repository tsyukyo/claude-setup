---
name: init
description: 現在のリポジトリに dev-team 構成（CLAUDE.md の委任ルールと .claude/settings.json）を導入する。新規プロジェクト立ち上げ時や、CLAUDE.md がないリポジトリで使う。
disable-model-invocation: true
---

# dev-team 構成をこのリポジトリに導入する

テンプレートは下に埋め込まれている（プラグインのディレクトリを読みに行く必要はない）。埋め込み部分は `scripts/sync-skill.sh` が `templates/` から生成するので手で編集しない。既存ファイルは上書きせず、ユーザーの作業を保護する。

## 手順

1. `git status` とブランチを確認する。未コミット変更があれば触れずに続け、報告に記載する。基準ブランチ上なら `chore/claude-setup` ブランチを作成する。
2. **CLAUDE.md**
   - ルートに `CLAUDE.md` がなければ、下の「テンプレート: CLAUDE.md」をそのまま書き出す。
   - 既にあれば、テンプレートの「委任ルール」以降のうち不足しているセクションだけを末尾に追記する。既存の記述は変更しない。
3. **.claude/settings.json**
   - なければ、下の「テンプレート: .claude/settings.json」をそのまま書き出す。
   - 既にあれば JSON としてマージする: 既存キーを優先し、`extraKnownMarketplaces`・`enabledPlugins`・`permissions.allow`・`permissions.deny` は和集合にする。`model` が既に設定されていれば変更しない。
   - `.claude/` への書き込みは保護されており、承認を求められることがある。拒否された場合は別の手段で書き込まず、作成すべき内容を報告に載せてユーザーに作成を依頼する。
4. **.gitignore**: `.claude/settings.local.json` と `.claude/worktrees/` がなければ追記する。
5. **プロジェクト情報の記入**: `dev-team:search` サブエージェント（なければ Explore を `model: haiku` で）にリポジトリをマッピングさせ、その結果で CLAUDE.md の「プロジェクト情報」（概要・技術スタック・基準ブランチ・各コマンド）を埋める。特定できない項目はコメントのまま残し、報告で要確認とする。
6. **検証**: `python3 -c 'import json;json.load(open(".claude/settings.json"))'` で JSON を確認し、CLAUDE.md に残ったプレースホルダ（`<!--`）を列挙する。
7. 変更をコミットする（メッセージ例: `chore: dev-team 構成を導入`）。push と PR 作成はリポジトリの運用方針に従う。

## 報告（日本語）

- 作成 / 追記 / スキップしたファイル
- 記入したプロジェクト情報と、要確認のまま残した項目
- ブランチ・コミット ID・push 状況

<!-- BEGIN TEMPLATES (scripts/sync-skill.sh が生成) -->

## テンプレート: CLAUDE.md

````markdown
# CLAUDE.md

<!-- dev-team template v1 — 共通ルール（言語・自律性・報告形式）は claude.ai 個人設定と ~/.claude/CLAUDE.md、Projects ではプロジェクト指示に置き、ここには重複して書かない -->

## プロジェクト情報

- 概要: <!-- このリポジトリが何をするものか 1〜2 行 -->
- 技術スタック: <!-- 言語・フレームワーク・主要ライブラリ -->
- 基準ブランチ: `main`
- コマンド:
  - セットアップ: <!-- 例: npm ci -->
  - テスト: <!-- 例: npm test -->
  - 型チェック / Lint: <!-- 例: npm run typecheck && npm run lint -->
  - ビルド: <!-- 例: npm run build -->

## 委任ルール

- **すべてのリポジトリ検索とテスト実行は Haiku 5.5 サブエージェント（search / grep / audit）に委任し、メインコンテキストを小さく保つ。**
- サブエージェントは `dev-team` プラグインが提供する（`dev-team:search` などの名前で表示される）。プラグインが読み込まれていない環境では、組み込みの Explore / general-purpose サブエージェントを `model: haiku` 指定で代用する。

## 役割分担

| 役割 | モデル | 担当 |
|---|---|---|
| メインセッション / スレッド | Sonnet 5.5 | 計画・実装・修正・コミット |
| `search` | Haiku 5.5 | リポジトリ構成のマッピング |
| `grep` | Haiku 5.5 | 定義・呼び出し箇所の列挙 |
| `audit` | Haiku 5.5（隔離 worktree） | 差分レビュー、テスト・型チェック・Lint |
| `advisor` | Opus 5.5（読み取り専用） | 重大判断の相談、マージ前サインオフ |

## 標準フロー

1. `search` で構成を把握し、`grep` で影響範囲を特定する（独立した調査は並列起動）
2. 重大な判断があれば `advisor` に相談する
3. 作業ブランチで実装し、ローカルコミットする（audit はコミット済みの内容しか見えない）
4. `audit` にブランチ名と基準ブランチを渡す → FAIL なら修正して 3 に戻る
5. `advisor` が必要な変更なら、差分要約と audit 結果を渡してサインオフを得る
6. push し、draft PR を作成する

## advisor を通す条件

- 必須: スキーマ・マイグレーション、認証・認可、課金、公開 API、データ削除、セキュリティ設定の変更
- 省略可: 上記に該当せず、変更が小規模（目安 3 ファイル以下）で audit が PASS

## 失敗時の扱い

- ネットワークエラー: 2s → 4s → 8s → 16s の指数バックオフで最大 4 回再試行
- テスト・ビルド失敗: 原因を修正してから再実行。同じ失敗が 2 回続いたら `advisor` に相談
- 権限拒否・必要なリポジトリ/秘密情報/コネクタの欠如: 代用・モック・推測をせず、不足しているものを具体的に報告して止まる
````

## テンプレート: .claude/settings.json

````json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "model": "sonnet",
  "extraKnownMarketplaces": {
    "tsyukyo-tools": {
      "source": {
        "source": "github",
        "repo": "tsyukyo/claude-setup"
      }
    }
  },
  "enabledPlugins": {
    "dev-team@tsyukyo-tools": true
  },
  "permissions": {
    "allow": [
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(git ls-files:*)",
      "Bash(git worktree list:*)"
    ],
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Bash(git push --force:*)",
      "Bash(git push -f:*)",
      "Bash(git reset --hard:*)"
    ]
  }
}
````
<!-- END TEMPLATES -->
