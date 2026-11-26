#!/bin/sh
# Tests the Git pre-push hook (.githooks/pre-push -> .claude/hooks/guard.py --pre-push) against a
# throwaway local bare remote. Never touches GitHub or this repo's own remote.
# Usage: tools/test_push_guard.sh   -> last line PUSH GUARD PASS (or PUSH GUARD FAIL)
# Why: a guard nobody has seen block anything can't be trusted, and testing against GitHub could
# push to the real main. A local bare remote proves each rule safely (docs/DECISIONS.md, Nov 21).
SRC=$(cd "$(git rev-parse --show-toplevel)" && pwd) || exit 1
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
FAILS=0
export GIT_AUTHOR_NAME=guard-test GIT_AUTHOR_EMAIL=guard@test GIT_COMMITTER_NAME=guard-test GIT_COMMITTER_EMAIL=guard@test

git init -q --bare -b main "$T/remote.git"
git init -q -b main "$T/work" && cd "$T/work" || exit 1
mkdir -p .claude/hooks .githooks tools
cp "$SRC/.claude/hooks/guard.py" .claude/hooks/ && cp "$SRC/.githooks/pre-push" .githooks/
cp "$SRC/tools/test.sh" tools/ && printf '.claude/state/\n' > .gitignore
printf 'test_cmd =\npass_line =\n' > .claude/hooks/guard.cfg
git config core.hooksPath .githooks && git remote add origin "$T/remote.git"
echo seed > README.md && git add -A && git commit -qm seed
git push -q --no-verify origin main 2>/dev/null   # seeding the test remote only

# expect <allowed|blocked> <name> <git args...>
expect() {
  want=$1; name=$2; shift 2
  if git "$@" >"$T/out" 2>&1; then got=allowed; else got=blocked; fi
  why=$(grep -m1 BLOCKED "$T/out")
  if [ "$got" = "$want" ]; then echo "PASS $name: $got ${why:+($why)}"
  else echo "FAIL $name: wanted $want, got $got"; cat "$T/out"; FAILS=$((FAILS+1)); fi
}

echo change >> README.md && git commit -qam "direct to main"
expect blocked "direct push to main" push origin main
expect blocked "push main under another local name" push origin HEAD:refs/heads/main
git reset -q --hard origin/main

git checkout -q -b feature && echo a > a.txt && git add a.txt && git commit -qm a
expect allowed "normal branch push" push -u origin feature
git commit -q --amend -m "a, rewritten"
expect blocked "force push (--force)" push --force origin feature
expect blocked "force push (+refspec)" push origin +feature
expect blocked "force push (--force-with-lease)" push --force-with-lease origin feature
git reset -q --hard origin/feature

echo b > b.txt && git add b.txt && git commit -qm b
expect allowed "fast-forward push to the same branch" push origin feature

echo "TOKEN=x" > .env && git add -f .env && git commit -qm "oops"
echo c > c.txt && git add c.txt && git commit -qm "later commit hides nothing"
expect blocked "secret file (.env) in pushed commits" push origin feature
git reset -q --hard origin/feature
mkdir -p signing && echo k > signing/game.keystore && git add -f signing/game.keystore && git commit -qm key
expect blocked "plain signing key in pushed commits" push origin feature
git reset -q --hard origin/feature

# Empty test_cmd (a design-only repo like hunter): code pushes are not gated.
echo 'extends Node' > game.gd && git add game.gd && git commit -qm code
expect allowed "code push with empty test_cmd (no test gate)" push origin feature

# With a test command: code must have passed tools/test.sh on exactly this tree.
printf 'test_cmd = true\npass_line =\n' > .claude/hooks/guard.cfg && git commit -qam "turn on test gate"
echo 'extends Node2D' > game.gd && git commit -qam "code change, tests not run"
expect blocked "code the tests didn't pass on" push origin feature
sh tools/test.sh >/dev/null
expect allowed "same code after tools/test.sh passed" push origin feature

expect blocked "deleting main on the remote" push origin :main
expect allowed "--no-verify skips the hook (CI is the backstop)" push --no-verify origin HEAD:refs/heads/main

if [ "$FAILS" -eq 0 ]; then echo "PUSH GUARD PASS"; else echo "PUSH GUARD FAIL ($FAILS)"; exit 1; fi
