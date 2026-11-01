#!/usr/bin/env bash
# Claude Code 構成ファイルの整合性チェック
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0
err() { echo "NG: $*" >&2; fail=1; }
json_ok() { python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$1" 2>/dev/null || err "$1 が不正な JSON です"; }

plugin=plugins/dev-team

# 1. JSON ファイル
for f in .claude/settings.json .claude-plugin/marketplace.json \
         "$plugin/.claude-plugin/plugin.json" "$plugin/templates/.claude/settings.json"; do
  [[ -f "$f" ]] || { err "$f がありません"; continue; }
  json_ok "$f"
done

# 2. マーケットプレイスがプラグインを指しているか
python3 - "$plugin" <<'PY' || fail=1
import json, sys, os
m = json.load(open(".claude-plugin/marketplace.json"))
p = json.load(open(os.path.join(sys.argv[1], ".claude-plugin/plugin.json")))
entry = next((e for e in m.get("plugins", []) if e.get("name") == p["name"]), None)
if entry is None:
    sys.exit(f"NG: marketplace.json に {p['name']} のエントリがありません")
if os.path.normpath(entry["source"]) != os.path.normpath(sys.argv[1]):
    sys.exit(f"NG: marketplace.json の source が {sys.argv[1]} ではありません")
if not p.get("version"):
    sys.exit("NG: plugin.json に version がありません")
PY

# 3. サブエージェントの frontmatter
declare -A expected_model=( [search]=haiku [grep]=haiku [audit]=haiku [advisor]=opus )
for name in "${!expected_model[@]}"; do
  f="$plugin/agents/${name}.md"
  [[ -f "$f" ]] || { err "$f がありません"; continue; }
  [[ "$(head -1 "$f")" == "---" ]] || err "$f: frontmatter がありません"
  fm=$(awk 'NR==1{next} /^---$/{exit} {print}' "$f")
  grep -qx "name: ${name}" <<<"$fm" || err "$f: name が ${name} ではありません"
  grep -q '^description: .\+' <<<"$fm" || err "$f: description がありません"
  grep -qx "model: ${expected_model[$name]}" <<<"$fm" || err "$f: model が ${expected_model[$name]} ではありません"
  grep -qE '^(permissionMode|hooks|mcpServers):' <<<"$fm" && err "$f: プラグインエージェントでは無視されるフィールドがあります"
done
grep -qx 'isolation: worktree' "$plugin/agents/audit.md" || err "audit.md: isolation: worktree がありません"
if grep -E '^tools:' "$plugin/agents/advisor.md" | grep -qE 'Edit|Write|Bash'; then
  err "advisor.md: 読み取り専用ツールのみにしてください"
fi
[[ -d .claude/agents ]] && err ".claude/agents/ は使わず、$plugin/agents/ に一本化してください"

# 4. スキル
f="$plugin/skills/init/SKILL.md"
[[ -f "$f" ]] || err "$f がありません"
grep -q '^description: .\+' "$f" || err "$f: description がありません"
bash scripts/sync-skill.sh --check || fail=1

# 5. 委任ルール（このリポジトリとテンプレートの両方）
for f in CLAUDE.md "$plugin/templates/CLAUDE.md"; do
  grep -q 'Haiku 5.5 サブエージェント' "$f" || err "$f に委任ルールがありません"
done

# 6. ユーザーレベル CLAUDE.md と setup script の同期
diff -q <(awk "/^cat > ~\/.claude\/CLAUDE.md <<'CLAUDE_MD_EOF'$/{p=1;next} /^CLAUDE_MD_EOF$/{p=0} p" cloud/setup-script.sh) user-level/CLAUDE.md >/dev/null \
  || err "cloud/setup-script.sh の内容が user-level/CLAUDE.md と一致しません"

# 7. プロジェクト指示の文字数（上限 16,000 文字）
chars=$(python3 - <<'PY'
import re
t = open("projects/project-instructions.md", encoding="utf-8").read()
m = re.search(r"```text\n(.*?)```", t, re.S)
print(len(m.group(1)) if m else -1)
PY
)
if (( chars < 0 )); then err "project-instructions.md に text コードブロックがありません"
elif (( chars > 16000 )); then err "プロジェクト指示が ${chars} 文字です（上限 16,000）"; fi

# 8. プラグインを変更したら version を上げているか（比較対象: origin/main。なければスキップ）
base="${VALIDATE_BASE:-origin/main}"
if git rev-parse -q --verify "$base" >/dev/null 2>&1 \
   && git cat-file -e "$base:$plugin/.claude-plugin/plugin.json" 2>/dev/null \
   && ! git diff --quiet "$base" -- "$plugin"; then
  old=$(git show "$base:$plugin/.claude-plugin/plugin.json" | python3 -c 'import json,sys;print(json.load(sys.stdin)["version"])')
  new=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["version"])' "$plugin/.claude-plugin/plugin.json")
  [[ "$old" != "$new" ]] || err "$plugin を変更していますが plugin.json の version が $base と同じ（$new）です"
fi

# 9. シェルスクリプトの構文
for f in scripts/*.sh cloud/*.sh; do bash -n "$f" || err "$f に構文エラーがあります"; done

if [[ $fail -eq 0 ]]; then echo "OK: すべてのチェックに合格しました（プロジェクト指示: ${chars} 文字）"; fi
exit $fail
