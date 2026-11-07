"""Apply dialogue rewrites safely.

Input: JSON files, each a list of {"file", "line", "old", "new"} (line is 1-based; old/new are the
string contents between the double quotes, escapes as they appear in source).
Checks before applying each one: old is on that line, {tokens} and %-codes unchanged, no raw
double quotes, not more than 1.5x longer, and the literal isn't used elsewhere in the code
(could be a key). Prints a report; --apply writes the files.
"""
import json, re, sys, glob, collections

TOK = re.compile(r"\{[a-zA-Z_0-9]+\}")
FMT = re.compile(r"%(?:%|[-+ 0#]*\d*(?:\.\d+)?[dsfxXc])")
RAWQ = re.compile(r'(?<!\\)"')

def main():
    apply = "--apply" in sys.argv
    files = [a for a in sys.argv[1:] if not a.startswith("--")]
    edits = []
    for f in files:
        edits += json.load(open(f))
    src = {}
    def get(p):
        if p not in src:
            src[p] = open(p, encoding="utf-8").read().split("\n")
        return src[p]
    allcode = "\n".join(open(p, encoding="utf-8").read() for p in glob.glob("scripts/**/*.gd", recursive=True))
    ok, bad = 0, collections.Counter()
    for e in edits:
        lines = get(e["file"])
        i = e["line"] - 1
        old, new = e["old"], e["new"]
        why = None
        if old == new:
            continue
        lit = '"' + old + '"'
        if i >= len(lines) or lit not in lines[i]:
            why = "old not on line"
        elif sorted(TOK.findall(old)) != sorted(TOK.findall(new)):
            why = "tokens changed"
        elif FMT.findall(old) != FMT.findall(new):
            why = "format codes changed"
        elif RAWQ.search(new):
            why = "raw double quote"
        elif len(new) > max(1.5 * len(old), len(old) + 25):
            why = "too long"
        elif allcode.count(lit) > 1:
            why = "literal used elsewhere"
        if why:
            bad[why] += 1
            print(f"SKIP {why}: {e['file']}:{e['line']}: {old[:60]!r}")
            continue
        lines[i] = lines[i].replace(lit, '"' + new + '"', 1)
        ok += 1
    print(f"{ok} ok, {sum(bad.values())} skipped {dict(bad)}")
    if apply:
        for p, ls in src.items():
            open(p, "w", encoding="utf-8").write("\n".join(ls))

main()
