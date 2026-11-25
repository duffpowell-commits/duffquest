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

def code_hash(repo, at_head):
    """One hash over every code file's blob id: of HEAD, or of the working tree as it is now.
    tools/test.sh stores the working-tree one; a push needs HEAD's to match (renders, docs and
    other non-code files can change in between without re-running the tests)."""
    pat = re.compile(cfg(repo).get("code_files", CODE_DEFAULT))
    rows = []
    if at_head:
        for line in git(repo, "ls-tree", "-r", "HEAD").splitlines():
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
