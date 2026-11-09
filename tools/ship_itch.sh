#!/usr/bin/env bash
# One command: install tools if missing -> import -> tests -> smoke -> web export -> butler push to itch.
# Needs BUTLER_API_KEY in the env (from the Cloudflare D1 vault `duff-vault`, see CLAUDE_REFERENCE.md).
# Usage (repo root): BUTLER_API_KEY=... tools/ship_itch.sh   [--no-push] [--web-check]
#   --no-push    build only, don't upload
#   --web-check  after export, boot build/web in headless mobile Chrome (tools/web_boot_check.py);
#                fails the ship on any console error. Optional (needs python3 + playwright + Chrome).
set -euo pipefail
cd "$(dirname "$0")/.."
NO_PUSH=0; WEB_CHECK=0
for a in "$@"; do
  case "$a" in
    --no-push) NO_PUSH=1 ;;
    --web-check) WEB_CHECK=1 ;;
    *) echo "unknown flag: $a"; exit 2 ;;
  esac
done
GV=4.5-stable
T=${TOOLS_DIR:-/tmp/tools}; mkdir -p "$T"
# Per-run log dir, so parallel ships (several worktrees) don't clobber each other's logs.
L=$(mktemp -d /tmp/ship.XXXXXX)
echo "== logs in $L"

if ! command -v godot >/dev/null; then
  curl -sSL -o "$T/godot.zip" "https://github.com/godotengine/godot/releases/download/$GV/Godot_v${GV}_linux.x86_64.zip"
  unzip -qo "$T/godot.zip" -d "$T" && ln -sf "$T/Godot_v${GV}_linux.x86_64" /usr/local/bin/godot
fi
TPL=${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${GV/-/.}
if [ ! -f "$TPL/web_nothreads_release.zip" ]; then
  curl -sSL -o "$T/tpl.tpz" "https://github.com/godotengine/godot/releases/download/$GV/Godot_v${GV}_export_templates.tpz"
  mkdir -p "$TPL" && unzip -qo -j "$T/tpl.tpz" 'templates/web*' -d "$TPL"
fi
if [ "$NO_PUSH" = 0 ] && ! command -v butler >/dev/null; then
  curl -sSL -o "$T/butler.zip" https://broth.itch.zone/butler/linux-amd64/LATEST/archive/default
  unzip -qo "$T/butler.zip" -d "$T/butler" && chmod +x "$T/butler/butler" && ln -sf "$T/butler/butler" /usr/local/bin/butler
fi
command -v xvfb-run >/dev/null || apt-get install -y -qq xvfb >/dev/null

echo "== import"; godot --headless --path . --import >"$L/import.log" 2>&1
echo "== test_daily"; godot --headless --path . --script tools/test_daily.gd 2>&1 | tee "$L/test.log" | tail -1
grep -q "ALL PASS" "$L/test.log" || { echo "TESTS FAILED"; exit 1; }
echo "== smoke (600 frames)"; mkdir -p "$L/smoke"
xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/smoke.tscn --fixed-fps 30 \
  --write-movie "$L/smoke/f.png" --quit-after 600 >"$L/smoke.log" 2>&1
! grep -E "SCRIPT ERROR|Parse Error" "$L/smoke.log" || { echo "SMOKE FAILED"; exit 1; }
rm -rf "$L/smoke"
echo "== export web"; rm -rf build/web && mkdir -p build/web && touch build/.gdignore
godot --headless --path . --export-release "Web" build/web/index.html >"$L/export.log" 2>&1
[ -f build/web/index.pck ] || { echo "EXPORT FAILED"; tail "$L/export.log"; exit 1; }
! grep -qa -E "glpat-|BUTLER_API_KEY=" build/web/index.pck || { echo "SECRET IN BUILD"; exit 1; }
du -sh build/web
if [ "$WEB_CHECK" = 1 ]; then
  echo "== web boot check (headless mobile Chrome)"
  python3 tools/web_boot_check.py --no-export || { echo "WEB CHECK FAILED"; exit 1; }
fi
[ "$NO_PUSH" = 1 ] && exit 0
: "${BUTLER_API_KEY:?set BUTLER_API_KEY (vault: duff-vault)}"
echo "== butler push"; butler push build/web dufftkyosht/duff-quest:html --userversion "$(git rev-parse --short HEAD)"
