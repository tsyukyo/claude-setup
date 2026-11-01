# Claude Code Projects 立ち上げガイド

Claude Code Projects（claude.ai/code・デスクトップアプリの Code タブ・モバイルアプリ）で新しいプロジェクトを作るときの手順と、各入力欄に書く内容です。
公式ドキュメント: <https://code.claude.com/docs/en/claude-projects>

## Projects で読み込まれるもの・読み込まれないもの

この構成は次の仕様を前提にしています。

| リポジトリ内のもの | Projects のクラウドスレッド | この構成での対応 |
|---|---|---|
| ルートの `CLAUDE.md`・`.claude/CLAUDE.md`・`.claude/rules/` | 読み込まれる | 委任ルールは `CLAUDE.md` に置く |
| `.claude/agents/`・`.claude/skills/` | **読み込まれない** | `dev-team` プラグインにまとめ、Project settings → Plugins で追加 |
| `.claude/settings.json`（model・権限・hooks・env・プラグイン） | **適用されない** | モデルは Project settings → General で指定。権限は auto mode とスレッド内の承認 |
| 手元の `~/.claude/CLAUDE.md` | 読み込まれない | クラウド環境の Setup script で書き出す（`cloud/setup-script.sh`） |
| claude.ai の個人設定・コネクタ | 使われる | `claude-ai/personal-preferences.md` を貼り付け |

> **注意: Projects ではリポジトリの deny ルールが効きません。** `.env` の読み取り禁止や強制 push の禁止は、プロジェクト指示の文言と auto mode・スレッド内の承認だけが頼りです。秘密情報はリポジトリに置かず、クラウド環境のネットワークシークレットに置いてください。

## 一度だけ行う準備

1. **プラン**: Pro / Max / Ultra で、サイドバーに **Projects**（または **More** の中）が表示されていること。
2. **GitHub**: 対象リポジトリに Claude GitHub App をインストールし、接続した GitHub アカウントに push 権限があること（`/web-setup` のトークンだけでは不足）。
3. **プラグインのマーケットプレイス登録**: claude.ai の **Customize → Plugins → Add** から GitHub リポジトリ `tsyukyo/claude-setup` をマーケットプレイスとして追加し、`dev-team` をインストールする。リポジトリが非公開で追加できない場合は、`bash scripts/package-plugin.sh` で作った zip を **Add → Upload plugin** でアップロードする（zip は自動更新されないので、プラグインの version を上げるたびに再アップロードする）。
4. **claude.ai 個人設定**: `claude-ai/personal-preferences.md` のコードブロックを貼り付ける。
5. **クラウド環境**: claude.ai/code の環境設定で自分専用の環境を作り、Setup script に `cloud/setup-script.sh` の中身を貼り付ける。必要なら許可ドメイン・ネットワークシークレットもここで設定する（秘密情報は環境変数ではなくネットワークシークレットに置く）。

## New project ダイアログに書く内容

| 欄 | 書く内容 | 例 |
|---|---|---|
| **Name**（必須） | 継続的に追加していく 1 つの作業の流れの名前 | `kakeibo-web MVP` |
| **Goal**（任意） | 達成したいことを 1 行で。測れる形にする | `kakeibo-web の MVP を完成させ、Workers に公開する` |
| **Context**（任意） | ほぼすべてのタスクで触るリポジトリ 1〜2 個と、スレッドに読ませたい資料（仕様書・デザイン・API 仕様など） | `tsyukyo/kakeibo-web`、`docs/要件定義.pdf` |

- リポジトリは「ほとんどのタスクで使うもの」だけを追加し、他はプロジェクト指示に名前を書いておく（スレッドが必要なときに自分で追加する）。
- アップロードしたファイルはコピーなので、手元で更新したら Library タブから再アップロード（Replace）する。

## 作成後に Project settings で設定する内容

| 設定 | 推奨値 | 理由 |
|---|---|---|
| General → **Thread model / effort** | Sonnet 5.5 / medium〜high | 実装の主体。既定は Opus なので必ず変更する |
| General → **Coordinator model / effort** | Opus 5.5 / low | タスク分割と進捗判断という「大きな判断」を担い、読むのは報告だけなので消費は小さい |
| Memory → **Project instructions** | `projects/project-instructions.md` を記入して貼り付け | すべての新規スレッドとコーディネーターに渡される |
| Environment → **Repositories** | ダイアログで追加したもの | — |
| Environment → **Cloud environment** | 準備 5 で作った環境 | Setup script で `~/.claude/CLAUDE.md` を配置するため |
| **Plugins** | `dev-team` | search / grep / audit / advisor と `/dev-team:init` をスレッドで使うため |

設定の変更は**新しく始まるスレッド**にだけ反映されます。実行中のスレッドには反映されません。

## 最初に送るメッセージの例

新規リポジトリ（CLAUDE.md がまだない）の場合:

```text
<owner/repo> に /dev-team:init を実行して dev-team 構成を導入し、draft PR を作成してください。
完了したら、リポジトリの現状と MVP までのタスク分割案を提案し、私の go を待ってからスレッドを開始してください。
```

既存リポジトリの場合:

```text
まず dev-team:search でリポジトリ全体を把握し、何も変更せずに現状の課題と次のタスク案を提案してください。
同時に動かすスレッドは最大 2 つにしてください。
```

## 運用のコツ

- スレッドの作業を修正させたら「この修正を覚えておいて」と伝える。プロジェクトメモリに保存され、以後のスレッドが最初から従う。
- 必ず守らせたい運用ルール（同時スレッド数、PR を作るタイミングなど）は、会話で伝えるだけでなくプロジェクト指示に書く。会話での指示は「好み」として扱われ、強制ではない。
- 小さな質問は「スレッドを立てずにここで答えて」と伝えると使用量を節約できる。
- 使用量は Project settings → Usage でスレッド別・モデル別に確認できる。最初のプロジェクトでは、ここで Haiku（search / grep / audit）と Opus（advisor）が実際に使われているかを一度確認する。
