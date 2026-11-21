#!/bin/sh
# Runs this repo's tests (test_cmd in .claude/hooks/guard.cfg) on the working tree and, if they
# pass, records the tree's hash so the push guard (.claude/hooks/guard.py) lets the push through.
# Usage: tools/test.sh   (from the repo root, or any folder inside it)
cd "$(git rev-parse --show-toplevel)" || exit 1
CMD=$(sed -n 's/^test_cmd *= *//p' .claude/hooks/guard.cfg)
PASS=$(sed -n 's/^pass_line *= *//p' .claude/hooks/guard.cfg)
[ -z "$CMD" ] && { echo "no test_cmd in .claude/hooks/guard.cfg"; exit 0; }
LOG=$(mktemp); RC=$(mktemp)
( XDG_DATA_HOME=${XDG_DATA_HOME:-$(mktemp -d)} sh -c "$CMD"; echo $? > "$RC" ) 2>&1 | tee "$LOG"
STATUS=$(cat "$RC"); rm -f "$RC"
if [ -n "$PASS" ] && ! grep -qE "$PASS" "$LOG"; then STATUS=1; fi
if grep -q "SCRIPT ERROR" "$LOG"; then STATUS=1; fi
rm -f "$LOG"
if [ "$STATUS" -ne 0 ]; then echo "TESTS FAILED: push stays blocked"; exit 1; fi
# Hash of the code files as they are now; the push guard checks the pushed commit has the same code.
TREE=$(python3 .claude/hooks/guard.py --hash "$PWD")
mkdir -p .claude/state && echo "$TREE" > .claude/state/tests_pass
echo "TESTS PASS: code $TREE recorded; commit this code and push"
