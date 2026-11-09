"""Apply a knockout dialogue rewrite file to data/knockouts.json, touching only the changed lines.

    python3 tools/apply_ko_rewrites.py [tools/rewrites/ko_variety_m14.json]

Rejects a rewrite that drops or adds a {token}, or runs past MAX_LEN characters (the beat caption box).
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data" / "knockouts.json"
MAX_LEN = 200


def main():
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "tools" / "rewrites" / "ko_variety_m14.json"
    rw = {k: v for k, v in json.loads(src.read_text()).items() if not k.startswith("_")}
    old = json.loads(DATA.read_text())
    lines = DATA.read_text().split("\n")
    cur, done, bad = None, 0, []
    for i, line in enumerate(lines):
        m = re.match(r'\s{2}"(\w+)": \{\s*$', line)
        if m:
            cur = m.group(1)
            continue
        f = re.match(r'(\s*)"(\w+)": (".*")(,?)\s*$', line)
        if not (f and cur in rw and f.group(2) in rw[cur]):
            continue
        field, new = f.group(2), rw[cur][field := f.group(2)]
        was = old[cur][field]
        if set(re.findall(r"\{\w+\}", was)) != set(re.findall(r"\{\w+\}", new)):
            bad.append(f"{cur}.{field}: tokens changed")
            continue
        if len(new) > MAX_LEN:
            bad.append(f"{cur}.{field}: {len(new)} chars > {MAX_LEN}")
            continue
        lines[i] = f'{f.group(1)}"{field}": {json.dumps(new, ensure_ascii=False)}{f.group(4)}'
        done += 1
    want = sum(len(v) for v in rw.values())
    if bad or done != want:
        print("NOT applied:", bad, f"{done}/{want} matched")
        sys.exit(1)
    DATA.write_text("\n".join(lines))
    json.loads(DATA.read_text())  # still valid
    print(f"applied {done} lines")


if __name__ == "__main__":
    main()
