#!/bin/sh
# Tests tools/rule_lock.py (which PR changes count as rule changes) and guard.py rule 6 (agents
# never add the duff-ok label), in a throwaway local repo. Never touches GitHub.
# Usage: tools/test_rule_lock.sh   -> last line RULE LOCK PASS (or RULE LOCK FAIL)
# Why (Nov 24, 2026): a lock nobody has seen fail can't be trusted.
SRC=$(cd "$(dirname "$0")/.." && pwd)
T=$(mktemp -d); cd "$T" || exit 1
export GIT_AUTHOR_NAME=lock-test GIT_AUTHOR_EMAIL=lock@test GIT_COMMITTER_NAME=lock-test GIT_COMMITTER_EMAIL=lock@test
git init -q . && mkdir -p standards scripts
printf '# Game\n\n## Where things stand\n- M1 done\n\n## Hard rules\n- no ads\n' > CLAUDE.md
echo "rule" > standards/00-core.md; echo "code" > scripts/game.gd
git add -A && git commit -qm base && BASE=$(git rev-parse HEAD)
FAILS=0
expect() {  # expect <want exit> <label>
  OUT=$(python3 "$SRC/tools/rule_lock.py" "$BASE" HEAD); RC=$?
  if [ "$RC" = "$1" ]; then echo "PASS $2"; else echo "FAIL $2 (exit $RC: $OUT)"; FAILS=$((FAILS+1)); fi
  git reset -q --hard "$BASE"
}
echo "more code" >> scripts/game.gd; git commit -qam code; expect 0 "code change is not a rule change"
sed -i 's/M1 done/M2 done/' CLAUDE.md; git commit -qam handoff; expect 0 "CLAUDE.md handoff section is free"
sed -i 's/no ads/ads ok/' CLAUDE.md; git commit -qam rules; expect 1 "CLAUDE.md rules section is locked"
echo "new" >> standards/00-core.md; git commit -qam std; expect 1 "standards/ is locked"
echo "x" > AGENTS.md; git add AGENTS.md; git commit -qm agents; expect 1 "AGENTS.md is locked"
git mv standards/00-core.md docs-old.md; git commit -qm move; expect 1 "moving a file out of standards/ is locked"
sed -i '1i @EXTRA_RULES.md' CLAUDE.md; git commit -qam imp; expect 1 "CLAUDE.md top (@imports) is locked"
printf '\n## Hard rules\n- second\n' >> CLAUDE.md; git commit -qam dup; expect 1 "a repeated rules heading is locked too"
OUT=$(python3 "$SRC/tools/rule_lock.py" deadbeef HEAD 2>/dev/null); RC=$?
if [ "$RC" = 2 ]; then echo "PASS a bad base fails closed (exit 2)"; else echo "FAIL a bad base fails closed (exit $RC)"; FAILS=$((FAILS+1)); fi
git checkout -q -b side; echo "code" >> scripts/game.gd; git commit -qam side
git checkout -q -; echo "main rule" >> standards/00-core.md; git commit -qam mainrule; NEWBASE=$(git rev-parse HEAD)
OUT=$(python3 "$SRC/tools/rule_lock.py" "$NEWBASE" side); RC=$?
if [ "$RC" = 0 ]; then echo "PASS a rule change already on main doesn't flag a code PR"; else echo "FAIL main's rule change flagged a code PR ($OUT)"; FAILS=$((FAILS+1)); fi
git reset -q --hard "$BASE"
guard() {  # guard <want exit> <label> <json>
  [ -f "$SRC/.claude/hooks/guard.py" ] || return 0   # repo without the Claude guard
  echo "$3" | python3 "$SRC/.claude/hooks/guard.py" 2>/dev/null; RC=$?
  if [ "$RC" = "$1" ]; then echo "PASS $2"; else echo "FAIL $2 (exit $RC)"; FAILS=$((FAILS+1)); fi
}
guard 2 "guard blocks gh adding duff-ok" '{"tool_name":"Bash","tool_input":{"command":"gh pr edit 5 --add-label duff-ok"}}'
guard 2 "guard blocks an MCP call setting duff-ok" '{"tool_name":"mcp__github__issue_write","tool_input":{"labels":["bug","duff-ok"]}}'
guard 0 "guard lets other labels through" '{"tool_name":"mcp__github__issue_write","tool_input":{"labels":["bug"]}}'
guard 2 "guard blocks DUFF-OK in any case" '{"tool_name":"Bash","tool_input":{"command":"gh pr edit 5 --add-label DUFF-OK"}}'
guard 2 "guard blocks duff-ok inside a label string" '{"tool_name":"mcp__github__issue_write","tool_input":{"labels":"bug,duff-ok"}}'
guard 2 "guard blocks a POST to the labels API" '{"tool_name":"Bash","tool_input":{"command":"gh api -X POST repos/o/r/issues/5/labels -f labels[]=duff-ok"}}'
guard 0 "guard lets a read of label history through" '{"tool_name":"Bash","tool_input":{"command":"gh api repos/o/r/issues/5/events | grep duff-ok"}}'
cd / && rm -rf "$T"
if [ "$FAILS" = 0 ]; then echo "RULE LOCK PASS"; else echo "RULE LOCK FAIL"; exit 1; fi
