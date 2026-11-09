#!/usr/bin/env bash
# One command: install tools if missing -> import -> tests -> smoke -> web export -> butler push to itch.
# Needs BUTLER_API_KEY in the env (from the Cloudflare D1 vault `duff-vault`, see CLAUDE_REFERENCE.md).
# Usage (repo root): BUTLER_API_KEY=... tools/ship_itch.sh   [--no-push]
set -euo pipefail
cd "$(dirname "$0")/.."
GV=4.5-stable
T=${TOOLS_DIR:-/tmp/tools}; mkdir -p "$T"

if ! command -v godot >/dev/null; then
  curl -sSL -o "$T/godot.zip" "https://github.com/godotengine/godot/releases/download/$GV/Godot_v${GV}_linux.x86_64.zip"
  unzip -qo "$T/godot.zip" -d "$T" && ln -sf "$T/Godot_v${GV}_linux.x86_64" /usr/local/bin/godot
fi
TPL=${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${GV/-/.}
if [ ! -f "$TPL/web_nothreads_release.zip" ]; then
  curl -sSL -o "$T/tpl.tpz" "https://github.com/godotengine/godot/releases/download/$GV/Godot_v${GV}_export_templates.tpz"
  mkdir -p "$TPL" && unzip -qo -j "$T/tpl.tpz" 'templates/web*' -d "$TPL"
fi
if ! command -v butler >/dev/null; then
  curl -sSL -o "$T/butler.zip" https://broth.itch.zone/butler/linux-amd64/LATEST/archive/default
  unzip -qo "$T/butler.zip" -d "$T/butler" && chmod +x "$T/butler/butler" && ln -sf "$T/butler/butler" /usr/local/bin/butler
fi
command -v xvfb-run >/dev/null || apt-get install -y -qq xvfb >/dev/null

echo "== import"; godot --headless --path . --import >/tmp/ship_import.log 2>&1
# big HD art ships as lossy WebP (masters untouched); a 2nd import picks up brand-new drops
python3 tools/set_lossy_imports.py | tee -a /tmp/ship_import.log | grep -q " 0 .import" \
  || godot --headless --path . --import >>/tmp/ship_import.log 2>&1
echo "== test_daily"; godot --headless --path . --script tools/test_daily.gd 2>&1 | tee /tmp/ship_test.log | tail -1
grep -q "ALL PASS" /tmp/ship_test.log || { echo "TESTS FAILED"; exit 1; }
echo "== smoke (600 frames)"; rm -rf /tmp/ship_smoke && mkdir -p /tmp/ship_smoke
xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/smoke.tscn --fixed-fps 30 \
  --write-movie /tmp/ship_smoke/f.png --quit-after 600 >/tmp/ship_smoke.log 2>&1
! grep -E "SCRIPT ERROR|Parse Error" /tmp/ship_smoke.log || { echo "SMOKE FAILED"; exit 1; }
echo "== export web"; rm -rf build/web && mkdir -p build/web
godot --headless --path . --export-release "Web" build/web/index.html >/tmp/ship_export.log 2>&1
[ -f build/web/index.pck ] || { echo "EXPORT FAILED"; tail /tmp/ship_export.log; exit 1; }
! grep -qa -E "glpat-|BUTLER_API_KEY=" build/web/index.pck || { echo "SECRET IN BUILD"; exit 1; }
du -sh build/web
[ "${1:-}" = "--no-push" ] && exit 0
: "${BUTLER_API_KEY:?set BUTLER_API_KEY (vault: duff-vault)}"
echo "== butler push"; butler push build/web dufftkyosht/duff-quest:html --userversion "$(git rev-parse --short HEAD)"
