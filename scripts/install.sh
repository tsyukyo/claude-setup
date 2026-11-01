#!/usr/bin/env bash
# dev-team 構成を対象リポジトリに導入する（既存ファイルは上書きしない）
#
# 使い方:
#   scripts/install.sh <対象リポジトリのパス> [--with-agents]
#
#   --with-agents  サブエージェントを対象リポジトリの .claude/agents/ にもコピーする。
#                  プラグインを読み込まない「単体のクラウドセッション」で使う場合に指定する。
#                  （Projects のスレッドは .claude/agents/ を読まないので、プラグインで追加すること）
set -euo pipefail

src="$(cd "$(dirname "$0")/.." && pwd)/plugins/dev-team"
target="${1:-}"
with_agents=false
case "${2:-}" in
  "") ;;
  --with-agents) with_agents=true ;;
  *) target="" ;;  # 不明なオプションは使い方を表示して終了する
esac

if [[ -z "$target" || ! -d "$target" || $# -gt 2 ]]; then
  echo "使い方: $0 <対象リポジトリのパス> [--with-agents]" >&2
  exit 1
fi
target="$(cd "$target" && pwd)"

copy_if_absent() {
  local from="$1" to="$2"
  if [[ -e "$to" || -L "$to" ]]; then
    echo "スキップ（既存）: ${to#"$target"/}"
  else
    mkdir -p "$(dirname "$to")"
    cp "$from" "$to"
    echo "作成: ${to#"$target"/}"
  fi
}

copy_if_absent "$src/templates/CLAUDE.md" "$target/CLAUDE.md"
copy_if_absent "$src/templates/.claude/settings.json" "$target/.claude/settings.json"

if $with_agents; then
  for f in "$src"/agents/*.md; do
    copy_if_absent "$f" "$target/.claude/agents/$(basename "$f")"
  done
fi

if ! grep -qs '^\.claude/settings\.local\.json$' "$target/.gitignore"; then
  printf '\n# Claude Code のローカル専用設定と一時 worktree\n.claude/settings.local.json\n.claude/worktrees/\n' >> "$target/.gitignore"
  echo "追記: .gitignore"
fi

cat <<'EOF'

次の手順:
  1. CLAUDE.md の「プロジェクト情報」を記入する（Claude Code で /dev-team:init を実行すると自動で記入できる）
  2. 既存ファイルがスキップされた場合は、テンプレートとの差分を手動でマージする
  3. 変更をコミットする
EOF
