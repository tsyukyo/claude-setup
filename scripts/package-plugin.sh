#!/usr/bin/env bash
# dev-team プラグインを claude.ai の「Upload plugin」用 zip にまとめる
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(python3 -c 'import json;print(json.load(open("plugins/dev-team/.claude-plugin/plugin.json"))["version"])')
mkdir -p dist
out="dist/dev-team-${version}.zip"
rm -f "$out"
(cd plugins && zip -qr "../$out" dev-team -x '*.DS_Store')
echo "作成しました: $out"
