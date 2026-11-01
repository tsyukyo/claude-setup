#!/usr/bin/env bash
# Claude Code 設定ファイルの整合性チェック
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0
err() { echo "NG: $*" >&2; fail=1; }

# settings.json が有効な JSON か
python3 -c 'import json,sys; json.load(open(sys.argv[1]))' .claude/settings.json \
  || err ".claude/settings.json が不正な JSON です"

# 各エージェントの frontmatter を確認
declare -A expected_model=( [search]=haiku [grep]=haiku [audit]=haiku [advisor]=opus )
for name in "${!expected_model[@]}"; do
  f=".claude/agents/${name}.md"
  [[ -f "$f" ]] || { err "$f がありません"; continue; }
  [[ "$(head -1 "$f")" == "---" ]] || err "$f: frontmatter がありません"
  fm=$(awk 'NR==1{next} /^---$/{exit} {print}' "$f")
  grep -qx "name: ${name}" <<<"$fm" || err "$f: name が ${name} ではありません"
  grep -q '^description: .\+' <<<"$fm" || err "$f: description がありません"
  grep -qx "model: ${expected_model[$name]}" <<<"$fm" || err "$f: model が ${expected_model[$name]} ではありません"
done

# audit は隔離 worktree、advisor は読み取り専用
grep -qx 'isolation: worktree' .claude/agents/audit.md || err "audit.md: isolation: worktree がありません"
if grep -E '^tools:' .claude/agents/advisor.md | grep -qE 'Edit|Write|Bash'; then
  err "advisor.md: 読み取り専用ツールのみにしてください"
fi

# 委任ルールが CLAUDE.md にあるか
grep -q 'Haiku 5.5 サブエージェント' CLAUDE.md || err "CLAUDE.md に委任ルールがありません"

if [[ $fail -eq 0 ]]; then echo "OK: すべてのチェックに合格しました"; fi
exit $fail
