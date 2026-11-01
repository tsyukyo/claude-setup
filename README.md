# claude-setup

Claude Code を「Sonnet 5.5 が実装し、Haiku 5.5 が並列で調査・監査し、Opus 5.5 が重大判断とサインオフを担う」構成で使うためのテンプレートと、`dev-team` プラグインの配布元です。
新しいプロジェクトを立ち上げるたびに、この構成を数ステップで導入できます。

```
メイン / スレッド (Sonnet 5.5) ── 計画・実装・修正・コミット
├── dev-team:search  (Haiku 5.5)               リポジトリ構成のマッピング
├── dev-team:grep    (Haiku 5.5)               定義・呼び出し箇所の列挙
├── dev-team:audit   (Haiku 5.5, 隔離 worktree) 差分レビュー＋テスト実行
└── dev-team:advisor (Opus 5.5, 読み取り専用)    重大判断・マージ前サインオフ
```

## どこで使うかで導入方法が変わる

Claude Code は使う場所によって読み込む設定が異なります。特に **Projects のスレッドはリポジトリの `.claude/agents/` と `.claude/settings.json` を読みません**。そのためサブエージェントはプラグインとして配布しています。

| 使う場所 | サブエージェント | ルール（委任・フロー） | モデル指定 |
|---|---|---|---|
| **Claude Code Projects**（Web / デスクトップ / モバイル） | Project settings → Plugins で `dev-team` を追加 | リポジトリの `CLAUDE.md` ＋プロジェクト指示 | Project settings → General |
| ローカル（ターミナル / IDE / デスクトップのローカル） | `.claude/settings.json` の `enabledPlugins` で自動提案 | リポジトリの `CLAUDE.md` | `.claude/settings.json` の `model` |
| 単体のクラウドセッション（Projects 外） | `install.sh --with-agents` でリポジトリにコミット | リポジトリの `CLAUDE.md` | `.claude/settings.json` の `model` |

## クイックスタート

### A. Claude Code Projects で新しいプロジェクトを始める（推奨）

[`projects/README.md`](projects/README.md) に、準備、New project ダイアログの各欄に書く内容、Project settings の推奨値、最初に送るメッセージまでをまとめています。要点は次のとおりです。

1. claude.ai の **Customize → Plugins** でこのリポジトリをマーケットプレイスとして追加し、`dev-team` をインストールする
2. New project を作成し、4 つの基本設定を次のようにする（既定は「すべて Opus・high エフォート」で消費が最も大きい）

   | 設定 | 推奨値 |
   |---|---|
   | 何に取り組みますか？ | 成果と完了条件を 1 行で（例: `kakeibo-web の MVP を 11 月末までに Workers へ公開する`） |
   | コーディネーターモデル | Opus 5.5（エフォート欄があれば low） |
   | スレッドモデル | Sonnet 5.5 |
   | スレッドのエフォート | medium（バグ修正・既存コードの改修が中心なら high） |

3. **Project instructions** に [`projects/project-instructions.md`](projects/project-instructions.md) を記入して貼り付ける
4. **Plugins** に `dev-team` を追加する
5. 最初のメッセージで `/dev-team:init` を実行させ、リポジトリに CLAUDE.md を導入する

### B. ローカルの Claude Code で既存リポジトリに導入する

プラグインを入れて、リポジトリ内で初期化スキルを実行します。

```bash
claude plugin marketplace add tsyukyo/claude-setup
```

```bash
claude plugin install dev-team@tsyukyo-tools
```

対象リポジトリで Claude Code を起動し、`/dev-team:init` を実行します。CLAUDE.md と `.claude/settings.json` が作成（既存ならマージ）され、プロジェクト情報も自動で記入されます。

### C. スクリプトでファイルだけコピーする

```bash
bash scripts/install.sh /path/to/your-repo
```

単体のクラウドセッションでも使う場合は `--with-agents` を付けて、サブエージェントをリポジトリにコミットします。既存ファイルは上書きしません。

## 個人設定（一度だけ）

| ファイル | 設定先 |
|---|---|
| [`claude-ai/personal-preferences.md`](claude-ai/personal-preferences.md) | claude.ai の 設定 → プロフィール → 個人設定 |
| [`user-level/CLAUDE.md`](user-level/CLAUDE.md) | ローカルの `~/.claude/CLAUDE.md` |
| [`cloud/setup-script.sh`](cloud/setup-script.sh) | クラウド環境の Setup script（クラウドでも `~/.claude/CLAUDE.md` を有効にする） |

## ファイル構成

```
.claude-plugin/marketplace.json        マーケットプレイス定義（tsyukyo-tools）
plugins/dev-team/
  .claude-plugin/plugin.json           プラグイン定義（version を上げると利用者に更新が届く）
  agents/                              search / grep / audit / advisor
  skills/init/SKILL.md                 /dev-team:init（リポジトリ初期化）
  templates/CLAUDE.md                  導入先リポジトリ用 CLAUDE.md
  templates/.claude/settings.json      導入先リポジトリ用 settings.json
projects/README.md                     Projects 立ち上げガイド
projects/project-instructions.md       プロジェクト指示テンプレート
claude-ai/personal-preferences.md      claude.ai 個人設定
user-level/CLAUDE.md                   ~/.claude/CLAUDE.md
cloud/setup-script.sh                  クラウド環境の Setup script
scripts/install.sh                     ファイルコピー型の導入スクリプト
scripts/package-plugin.sh              claude.ai アップロード用 zip の作成（マーケットプレイスを使えない場合の代替）
scripts/sync-skill.sh                  templates/ を /dev-team:init の SKILL.md に埋め込む
scripts/validate.sh                    整合性チェック（CI でも実行）
```

## 設計上のポイント

- **audit は `isolation: worktree`** で一時 worktree 内で動き、作業ブランチに触れません。worktree はコミット済みの内容から作られるため、audit の前に作業ブランチへコミットします。
- **advisor は読み取り専用**（Read / Grep / Glob のみ）で、判断に専念します。
- **モデル指定はエイリアス**（`sonnet` / `haiku` / `opus`）で、現時点では 5.5 系を指します。
- **正本は 1 か所**に置き、重複は validate.sh で同期を確認します（詳細は [`CLAUDE.md`](CLAUDE.md)）。

## 検証

```bash
bash scripts/validate.sh
```

```bash
claude plugin validate .
```
