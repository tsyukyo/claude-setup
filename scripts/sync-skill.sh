#!/usr/bin/env bash
# plugins/dev-team/templates/ の内容を /dev-team:init の SKILL.md に埋め込む
# 使い方: scripts/sync-skill.sh          … SKILL.md を更新
#         scripts/sync-skill.sh --check  … 差分があれば終了コード 1（validate.sh から使用）
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - "${1:-}" <<'PY'
import re, sys
root = "plugins/dev-team"
skill = f"{root}/skills/init/SKILL.md"
blocks = [("CLAUDE.md", "templates/CLAUDE.md", "markdown"),
          (".claude/settings.json", "templates/.claude/settings.json", "json")]
body = ""
for title, path, lang in blocks:
    content = open(f"{root}/{path}", encoding="utf-8").read().rstrip("\n")
    body += f"\n## テンプレート: {title}\n\n````{lang}\n{content}\n````\n"
s = open(skill, encoding="utf-8").read()
pat = re.compile(r"(<!-- BEGIN TEMPLATES[^\n]*-->\n).*?(<!-- END TEMPLATES -->)", re.S)
if not pat.search(s):
    sys.exit("NG: SKILL.md にテンプレートのマーカーがありません")
new = pat.sub(lambda m: m.group(1) + body + m.group(2), s)
if sys.argv[1] == "--check":
    sys.exit(0 if new == s else "NG: SKILL.md の埋め込みテンプレートが古いです（scripts/sync-skill.sh を実行）")
open(skill, "w", encoding="utf-8").write(new)
print("更新しました:", skill)
PY
