#!/usr/bin/env python3
"""Rule lock (Duff, Nov 24, 2026): a PR that changes the rules needs Duff's `duff-ok` label.

Usage: tools/rule_lock.py BASE HEAD   (git revisions; run inside the repo)
Prints each locked change, one per line. Exit 1 if there are any, else 0.
.github/workflows/rule_lock.yml runs it and sets the `rule-lock` commit status: failure until the
PR carries the `duff-ok` label. Agents never add that label (guard.py blocks Claude from it).
Why: on Nov 21 an agent rewrote Foxboard's no-likeness rule on its own, inside an art PR, and
wrote "Duff okayed it" into the PR. Rules are Duff's; a rule change has to be something he sees.

Locked: the rulebook files below, and in CLAUDE.md the top (before the first ## heading, where the
@imports are) plus the sections whose heading names rules, guards, signing or Claude-only notes
(the handoff sections stay free; every milestone edits them). Exit 2 = git error: counts as locked.
"""
import re, subprocess, sys

LOCKED_FILES = re.compile(
    r"^(AGENTS\.md|GROK_STANDARDS\.md|standards/.*|\.claude/.*|\.githooks/.*|docs/FRESH_EYES\.md"
    r"|\.github/workflows/(fresh_eyes|rule_lock)\.yml|tools/(rule_lock\.py|test_rule_lock\.sh|test_push_guard\.sh))$")
LOCKED_HEADING = re.compile(r"rule|guard|signing|claude-only", re.I)


def git(*args, must=True):
    """Fails closed (exit 2) on any git error, so a bad base never reads as "no rule changes"."""
    r = subprocess.run(["git", *args], capture_output=True, text=True)
    if r.returncode != 0:
        if must:
            sys.stderr.write("rule_lock: git %s failed: %s\n" % (" ".join(args), r.stderr.strip()))
            sys.exit(2)
        return ""
    return r.stdout


def sections(text):
    """{name: body} for the preamble (before the first '## ', which holds @imports) and every
    '## ' section whose heading is locked. Repeated headings get #2, #3... so none hide another."""
    out, cur, buf, seen = {}, "(top, before the first ## heading)", [], {}
    def close():
        if cur is not None:
            out[cur] = "\n".join(buf).strip()
    for line in text.splitlines():
        if line.startswith("## "):
            close()
            h = line[3:].strip()
            seen[h] = seen.get(h, 0) + 1
            name = h if seen[h] == 1 else "%s #%d" % (h, seen[h])
            cur, buf = (name if LOCKED_HEADING.search(h) else None), []
        elif cur is not None:
            buf.append(line)
    close()
    return out


def locked_changes(base, head):
    found = []
    # Merge-base diff (base...head): only what this PR changes. --no-renames: a move out of a locked
    # path lists the old path too.
    for path in git("diff", "--name-only", "--no-renames", "%s...%s" % (base, head)).splitlines():
        if LOCKED_FILES.match(path):
            found.append(path)
        elif path.endswith("CLAUDE.md"):
            mb = git("merge-base", base, head).strip()
            a = sections(git("show", "%s:%s" % (mb, path), must=False))
            b = sections(git("show", "%s:%s" % (head, path), must=False))
            for h in sorted(set(a) | set(b)):
                if a.get(h) != b.get(h):
                    found.append("%s (## %s)" % (path, h))
    return found


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("usage: tools/rule_lock.py BASE HEAD")
    hits = locked_changes(sys.argv[1], sys.argv[2])
    for h in hits:
        print(h)
    sys.exit(1 if hits else 0)
