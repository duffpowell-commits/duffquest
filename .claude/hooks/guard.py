#!/usr/bin/env python3
"""PreToolUse guard: blocks the mistakes Duff's sessions have had to be corrected on more than once.
Rules live here, not in prose, because a hook can't drift (Reddit r/ClaudeCode tip, Nov 2026:
"corrected twice = a hook"). Copy .claude/ into every game repo; per-repo settings sit in
.claude/hooks/guard.cfg. Each rule names the lesson it comes from. Delete a rule nobody trips.

  1. No force push (house rule in every repo). --force-with-lease stays allowed.
  2. No direct push to main: main ships to players, so it only moves by a merged PR with green CI.
  3. No push of code that hasn't passed the tests on exactly this tree (run tools/test.sh first).
     "Run the tests before every push" was prose for weeks and red builds still shipped.
  4. Signing keys: never written, generated or committed in plain form (one keystone for all
     games; Lethemoor keeps its own; a lost or changed key breaks in-app updates forever).
  5. No secrets in commits (.env, tokens, unencrypted keystores).
  6. Never add the `duff-ok` label: it is Duff's tap that approves a rule change (rule-lock,
     Nov 24, 2026). Checked on Bash (gh/curl) and on MCP tool calls that set labels.
Exit 2 + a reason on stderr = the call is blocked and the reason goes back to Claude.

The same rules also run as a plain Git pre-push hook for every agent, not just Claude Code:
.githooks/pre-push calls `guard.py --pre-push` (one-time setup per clone:
`git config core.hooksPath .githooks`). There a force push is any push that rewrites the remote
branch (git can't see the flags), so --force-with-lease is blocked too. `git push --no-verify`
skips the hook; CI and the fresh-eyes gate stay the backstop.
Why the Git hook (Nov 21, 2026): this file's PreToolUse mode only fires inside Claude Code, so Grok
and other agents could skip every rule. Sharing this one script keeps the rules from drifting.
"""
import json, os, re, subprocess, sys

def deny(msg):
    sys.stderr.write("BLOCKED by .claude/hooks/guard.py: " + msg + "\n")
    sys.exit(2)

def git(repo, *args):
    r = subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else ""

def cfg(repo):
    out = {}
    p = os.path.join(repo, ".claude/hooks/guard.cfg")
    if os.path.exists(p):
        for line in open(p):
            if "=" in line and not line.strip().startswith("#"):
                k, v = line.split("=", 1)
                out[k.strip()] = v.strip()
    return out

CODE_DEFAULT = r"\.(gd|tscn|tres|cfg|godot|gdshader|json|txt)$"
SKIP = (".claude/", "docs/", ".github/")

def code_hash(repo, at_head, rev="HEAD"):
    """One hash over every code file's blob id: of HEAD (or another commit, `rev`), or of the
    working tree as it is now. tools/test.sh stores the working-tree one; a push needs the pushed
    commit's to match (renders, docs and other non-code files can change in between without
    re-running the tests)."""
    pat = re.compile(cfg(repo).get("code_files", CODE_DEFAULT))
    rows = []
    if at_head:
        for line in git(repo, "ls-tree", "-r", rev).splitlines():
            meta, path = line.split("\t", 1)
            if pat.search(path) and not path.startswith(SKIP):
                rows.append(path + " " + meta.split()[2])
    else:
        files = git(repo, "ls-files", "-co", "--exclude-standard").splitlines()
        files = [f for f in files if pat.search(f) and not f.startswith(SKIP) and os.path.isfile(os.path.join(repo, f))]
        if files:
            r = subprocess.run(["git", "-C", repo, "hash-object", "--", *files], capture_output=True, text=True)
            rows = [f + " " + h for f, h in zip(files, r.stdout.split())]
    import hashlib
    return hashlib.sha1("\n".join(sorted(rows)).encode()).hexdigest()

def code_changed(repo, c):
    """True if this push carries files that the tests cover (default: Godot code and data)."""
    pat = re.compile(c.get("code_files", CODE_DEFAULT))
    base = git(repo, "merge-base", "HEAD", "origin/main") or git(repo, "rev-parse", "HEAD~1")
    files = git(repo, "diff", "--name-only", base, "HEAD").splitlines() if base else []
    return any(pat.search(f) and not f.startswith(SKIP) for f in files)

import shlex

SECRET = re.compile(r"(^|/)\.env(\.|$)|\.(jks|p12|pem)$|\.keystore$|(^|/)secrets?\.")


def segments(cmd):
    """Split a shell line into simple commands (on && || ; | and newlines), each as a token list.
    Quoted text stays inside its token, so a commit message can't trip a rule."""
    out, cur = [], []
    try:
        lex = shlex.shlex(cmd, posix=True, punctuation_chars=";&|")
        lex.whitespace_split = True
        lex.commenters = ""
        toks = list(lex)
    except ValueError:
        toks = cmd.split()
    for t in toks:
        if t and set(t) <= set(";&|"):
            if cur:
                out.append(cur)
            cur = []
        else:
            cur.append(t)
    if cur:
        out.append(cur)
    return out


def git_sub(tokens):
    """('push', args after it) for `git [-C dir] [-c k=v] push ...`, else (None, [], None)."""
    if not tokens or os.path.basename(tokens[0]) != "git":
        return None, [], None
    i, cdir = 1, None
    while i < len(tokens) and tokens[i].startswith("-"):
        if tokens[i] in ("-C", "-c") and i + 1 < len(tokens):
            if tokens[i] == "-C":
                cdir = tokens[i + 1]
            i += 2
        else:
            i += 1
    if i >= len(tokens):
        return None, [], cdir
    return tokens[i], tokens[i + 1:], cdir


def short_flags(args):
    return "".join(a[1:] for a in args if a.startswith("-") and not a.startswith("--"))


def check_bash(cmd, cwd):
    here = cwd
    adds = False
    for tok in segments(cmd):
        if tok and tok[0] == "cd" and len(tok) > 1:
            p = os.path.expanduser(tok[1])
            here = p if os.path.isabs(p) else os.path.join(here, p)
            continue
        sub, args, cdir = git_sub(tok)
        repo_dir = cdir if cdir and os.path.isabs(cdir) else (os.path.join(here, cdir) if cdir else here)
        repo = git(repo_dir, "rev-parse", "--show-toplevel") or None
        if tok and tok[0] == "keytool" and any(a.startswith("-genkey") for a in tok):
            deny("generating a signing key. Every game signs with the keystone (docs/SIGNING.md in "
                 "godot-game-starter); Lethemoor keeps its own. Never make another key.")
        if tok and tok[0] in ("cp", "mv", "tee", "install") and any(
                re.search(r"(^|/)signing/[^/]*\.(keystore|enc|sha256|jks)$", a) for a in tok[1:]):
            deny("writing a signing key file with %s. Keys never change; Lethemoor's never leaves its repo." % tok[0])
        if sub == "add":
            adds = True
        if sub == "push":
            flags = short_flags(args)
            if "--force" in args or "f" in flags or any(a.startswith("+") for a in args):
                deny("force push. House rule: never force push. Merge the remote branch in instead "
                     "(git fetch origin <branch> && git merge --no-edit FETCH_HEAD).")
            pos = [a for a in args if not a.startswith("-")]
            refs = pos[1:]
            if any(re.fullmatch(r"(\S*:)?(refs/heads/)?(main|master)", r) for r in refs):
                deny("direct push to main. main ships to players: push your branch, open a PR, "
                     "let CI go green, then merge the PR.")
            if repo and (not refs or refs == ["HEAD"]):
                if git(repo, "rev-parse", "--abbrev-ref", "HEAD") in ("main", "master"):
                    deny("push while on main. Make a branch (git checkout -b <name>), push that, open a PR.")
            if repo:
                c = cfg(repo)
                if c.get("test_cmd") and code_changed(repo, c):
                    mark = os.path.join(repo, ".claude/state/tests_pass")
                    passed = open(mark).read().strip() if os.path.exists(mark) else ""
                    if code_hash(repo, True) != passed:
                        deny("tests have not passed on the code in this commit. Run `tools/test.sh` in %s "
                             "(it runs: %s), commit, then push in a separate command (a commit and push in "
                             "one line is checked before the commit exists)." % (repo, c["test_cmd"]))
        if sub == "commit" and repo:
            files = git(repo, "diff", "--cached", "--name-only").splitlines()
            if adds or "a" in short_flags(args) or "--all" in args:
                files += git(repo, "ls-files", "-mo", "--exclude-standard").splitlines()
            bad = sorted({f for f in files if SECRET.search(f)})
            if bad:
                deny("secret-looking files would be committed: %s. Keys only go in as *.keystore.enc; "
                     "secrets live in GitHub Actions secrets, which Duff sets himself." % ", ".join(bad))


def check_write(path):
    if re.search(r"(^|/)signing/[^/]*\.(keystore|enc|sha256|jks)$", path or ""):
        deny("writing a signing key file (%s). Keys are made once by make_keystone.yml and never "
             "change; Lethemoor's key never goes into another repo." % path)

ZERO = re.compile(r"^0+$")


def is_ancestor(repo, old, new):
    return subprocess.run(["git", "-C", repo, "merge-base", "--is-ancestor", old, new],
                          capture_output=True).returncode == 0


def check_pre_push(repo, remote, lines):
    """Git pre-push hook (.githooks/pre-push). Git gives one stdin line per ref being pushed:
    <local ref> <local sha> <remote ref> <remote sha> (all zeros = the ref doesn't exist there).
    Why: the same rules as check_bash, for agents that aren't Claude Code. Git hides the push flags
    from hooks, so a force push is spotted by what it does (rewrites the remote branch)."""
    c = cfg(repo)
    pat = re.compile(c.get("code_files", CODE_DEFAULT))
    for line in lines:
        parts = line.split()
        if len(parts) != 4:
            continue
        _lref, lsha, rref, rsha = parts
        branch = re.sub(r"^refs/heads/", "", rref)
        if branch in ("main", "master"):
            deny("direct push to %s (rule 2). main ships to players: push your branch, open a PR, "
                 "let CI go green, then merge the PR." % branch)
        if ZERO.match(lsha):
            continue   # deleting a branch other than main: nothing is being pushed
        if not ZERO.match(rsha) and not is_ancestor(repo, rsha, lsha):
            deny("force push to %s (rule 1): this push would rewrite commits already on %s. Never "
                 "force push. Merge the remote branch in instead (git fetch %s %s && git merge "
                 "--no-edit FETCH_HEAD), then push." % (branch, remote, remote, branch))
        # Commits this push adds: past the remote branch, or (new branch) not on any remote ref yet.
        rng = [rsha + ".." + lsha] if not ZERO.match(rsha) else [lsha, "--not", "--remotes=" + remote]
        files = set(git(repo, "log", "--format=", "--name-only", "--diff-filter=ACMRT", *rng).splitlines())
        files.discard("")
        bad = sorted(f for f in files if SECRET.search(f))
        if bad:
            deny("secret-looking files in the commits being pushed (rule 5): %s. Remove them from "
                 "the commits (not just the next one). Keys only go in as *.keystore.enc; secrets "
                 "live in GitHub Actions secrets, which Duff sets himself." % ", ".join(bad))
        if c.get("test_cmd") and any(pat.search(f) and not f.startswith(SKIP) for f in files):
            mark = os.path.join(repo, ".claude/state/tests_pass")
            passed = open(mark).read().strip() if os.path.exists(mark) else ""
            if code_hash(repo, True, lsha) != passed:
                deny("tests have not passed on the code in %s (rule 3). Run `tools/test.sh` (it runs: "
                     "%s) until it prints TESTS PASS, commit that exact code, then push." % (branch, c["test_cmd"]))


def check_label(tool, inp):
    """Rule 6: agents never add Duff's duff-ok label (rule-lock approval)."""
    if tool == "Bash":
        cmd = inp.get("command", "")
        # Writes only (reading label history stays allowed); GitHub matches label names any case.
        if "duff-ok" in cmd.lower() and re.search(
                r"--add-label|--label\b|labels?\s*=|labels\[\]|-X\s*(POST|PUT|PATCH)|--method\s*(POST|PUT|PATCH)",
                cmd, re.I):
            deny("the duff-ok label is Duff's approval of a rule change; only he adds it (rule-lock).")
    elif tool.startswith("mcp__"):
        labels = inp.get("labels")
        if isinstance(labels, str):
            labels = labels.split(",")
        if isinstance(labels, list) and any(str(l).strip().lower() == "duff-ok" for l in labels):
            deny("the duff-ok label is Duff's approval of a rule change; only he adds it (rule-lock).")


def main():
    if len(sys.argv) > 2 and sys.argv[1] == "--hash":   # used by tools/test.sh
        print(code_hash(sys.argv[2], False))
        return
    if len(sys.argv) > 1 and sys.argv[1] == "--pre-push":   # used by .githooks/pre-push
        repo = git(os.getcwd(), "rev-parse", "--show-toplevel") or os.getcwd()
        remote = sys.argv[2] if len(sys.argv) > 2 else "origin"
        check_pre_push(repo, remote, sys.stdin.read().splitlines())
        return
    try:
        e = json.load(sys.stdin)
    except Exception:
        return
    tool, inp, cwd = e.get("tool_name", ""), e.get("tool_input", {}) or {}, e.get("cwd") or os.getcwd()
    check_label(tool, inp)
    if tool == "Bash":
        check_bash(inp.get("command", ""), cwd)
    elif tool in ("Write", "Edit", "MultiEdit", "NotebookEdit"):
        check_write(inp.get("file_path", ""))

if __name__ == "__main__":
    main()
