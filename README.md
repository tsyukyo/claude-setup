# claude-setup

Claude Code を「Sonnet 5.5 が実装し、Haiku 5.5 が並列で調査・監査し、Opus 5.5 が重大判断とサインオフを担う」構成で使うための設定一式です。
Opus のコンテキストを不要な作業で消費せず、メインセッションのコンテキストも小さく保つことを目的にしています。

```
メインセッション (Sonnet 5.5) ── 計画・実装・修正・コミット
├── search  (Haiku 5.5)              リポジトリ構成のマッピング
├── grep    (Haiku 5.5)              定義・呼び出し箇所の列挙
├── audit   (Haiku 5.5, 隔離worktree) 差分レビュー＋テスト実行
└── advisor (Opus 5.5, 読み取り専用)   重大判断・マージ前サインオフ
```

## ファイル構成

| パス | 適用範囲 | 内容 |
|---|---|---|
| `claude-ai/personal-preferences.md` | claude.ai の全会話 | 個人設定に貼り付ける文面（日本語・自律・検証・報告） |
| `user-level/CLAUDE.md` | 自分の全 Claude Code セッション | `~/.claude/CLAUDE.md` 用テンプレート |
| `CLAUDE.md` | このリポジトリ | 委任ルール・役割分担・標準フロー |
| `.claude/settings.json` | このリポジトリ | メインモデル（`sonnet`）と権限 |
| `.claude/agents/*.md` | このリポジトリ | 4 つのサブエージェント定義 |
| `scripts/validate.sh` | — | 設定の整合性チェック（CI でも実行） |

## 使い方

### 1. claude.ai 個人設定

`claude-ai/personal-preferences.md` のコードブロックを、claude.ai の「設定 → プロフィール → 個人設定」に貼り付けます。

### 2. 他のリポジトリへの導入

```bash
cp -r .claude CLAUDE.md /path/to/your-repo/
```

既存の `CLAUDE.md` がある場合は、「委任ルール」以降のセクションを追記してください。

### 3. ユーザーレベル設定（任意）

```bash
cp user-level/CLAUDE.md ~/.claude/CLAUDE.md
```

### 4. 動作確認

Claude Code で `/agents` を実行し、`search` / `grep` / `audit` / `advisor` が表示されることを確認します。

## 設計上のポイント

- **モデル指定はエイリアス**（`sonnet` / `haiku` / `opus`）。現時点では 5.5 系を指し、新モデル公開時に自動で追従します。固定したい場合は `claude-sonnet-5-5` などの完全な ID に置き換えてください。
- **audit は `isolation: worktree`** で一時 worktree 内で動き、作業ブランチを checkout・変更しません。worktree はコミット済みの内容から作られるため、audit の前に作業ブランチへローカルコミットします。
- **advisor は読み取り専用**（Read / Grep / Glob のみ）。判断に専念させ、編集はメインセッションが行います。
- **共通ルールとプロジェクトルールを分離**し、同じ内容を複数箇所に書かないようにしています。

## 検証

```bash
bash scripts/validate.sh
```
