#!/usr/bin/env python3
"""Play stats snapshot + play alerts for Duff's itch games.

Run by .github/workflows/play_stats.yml every 3 hours. Reads the itch `my-games` JSON
(stdin or --games FILE), appends one snapshot line to STATS_DIR/history.jsonl, updates
STATS_DIR/state.json and STATS_DIR/latest.json, and writes any alerts (one per line,
markdown) to --alerts FILE. The workflow turns each alert into a GitHub issue that
@mentions Duff, so his phone buzzes.

Alerts only fire while .github/play_alerts.json has "armed": true. The first armed run
stores a baseline (the debut moment), so Duff's own pre-debut test views don't count.

Rules, per game, counted from the baseline (no more than one spike alert per game per day):
- first traffic: 10 views since debut
- milestones: 100, 250, 500, 1k, 2.5k, 5k, 10k, 25k, 50k, 100k views since debut
- spike: views in the last 24 h >= 25 AND >= 2x the average day of the 7 days before
- money: any new purchase/tip (purchases_count goes up)
"""
import argparse
import json
import os
import sys
import time

FIRST_TRAFFIC = 10
MILESTONES = [100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000, 100000]
SPIKE_MIN = 25
SPIKE_RATIO = 2.0
DAY = 86400
FIELDS = ("views_count", "downloads_count", "purchases_count")


def load_json(path, default):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def snapshot(games_json, now):
    games = {}
    for g in games_json.get("games", []):
        row = {"title": g.get("title", "?"), "url": g.get("url", "")}
        for k in FIELDS:
            row[k] = int(g.get(k) or 0)
        # Keep any other count itch adds later (plays etc.) without code changes.
        for k, v in g.items():
            if k.endswith("_count") and k not in row and isinstance(v, (int, float)):
                row[k] = int(v)
        games[str(g.get("id"))] = row
    return {"ts": int(now), "games": games}


def read_history(path):
    out = []
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if line:
                    try:
                        out.append(json.loads(line))
                    except ValueError:
                        pass
    except OSError:
        pass
    return out


def views_at(history, gid, ts):
    """Views of game gid in the newest snapshot at or before ts (None if none)."""
    best = None
    for snap in history:
        if snap["ts"] <= ts and gid in snap["games"]:
            best = snap["games"][gid]["views_count"]
    return best


def fmt(n):
    return f"{n:,}"


def check(snap, history, state, armed):
    alerts = []
    now = snap["ts"]
    if not armed:
        return alerts
    base = state.setdefault("baseline", {})
    sent = state.setdefault("sent", {})
    if not base:
        state["armed_at"] = now
    for gid, g in snap["games"].items():
        if gid not in base:
            base[gid] = {k: g[k] for k in FIELDS}
            continue  # baseline run: nothing to compare yet
        s = sent.setdefault(gid, {"first": False, "milestones": [], "spike_day": "", "purchases": base[gid]["purchases_count"]})
        name = f"[{g['title']}]({g['url']})" if g["url"] else g["title"]
        since = g["views_count"] - base[gid]["views_count"]
        if not s["first"] and since >= FIRST_TRAFFIC:
            s["first"] = True
            alerts.append(f"People are finding {name}: {fmt(since)} views since debut.")
        for m in MILESTONES:
            if since >= m and m not in s["milestones"]:
                s["milestones"].append(m)
                if m == max(x for x in MILESTONES if since >= x):
                    alerts.append(f"{name} passed {fmt(m)} views since debut ({fmt(g['views_count'])} all time).")
        day_ago = views_at(history, gid, now - DAY)
        week_ago = views_at(history, gid, now - 8 * DAY)
        today = time.strftime("%Y-%m-%d", time.gmtime(now))
        if day_ago is not None and s["spike_day"] != today:
            last24 = g["views_count"] - day_ago
            avg = (day_ago - week_ago) / 7.0 if week_ago is not None else 0.0
            if last24 >= SPIKE_MIN and last24 >= SPIKE_RATIO * avg:
                s["spike_day"] = today
                vs = f", vs about {fmt(round(avg))} on a normal day" if week_ago is not None else ""
                alerts.append(f"Spike on {name}: {fmt(last24)} views in the last 24 hours{vs}.")
        if g["purchases_count"] > s["purchases"]:
            n = g["purchases_count"] - s["purchases"]
            alerts.append(f"Money: {n} new purchase{'s' if n > 1 else ''}/tip{'s' if n > 1 else ''} on {name}.")
        s["purchases"] = g["purchases_count"]
    return alerts


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--games", help="itch my-games JSON file (default stdin)")
    ap.add_argument("--stats", default="stats", help="stats dir (the stats branch checkout)")
    ap.add_argument("--config", default=".github/play_alerts.json")
    ap.add_argument("--alerts", default="alerts.txt")
    ap.add_argument("--now", type=float, default=None)
    a = ap.parse_args()

    games_json = load_json(a.games, None) if a.games else json.load(sys.stdin)
    if not games_json or "games" not in games_json:
        sys.exit("itch response has no games list: " + json.dumps(games_json)[:200])
    armed = bool(load_json(a.config, {}).get("armed"))
    os.makedirs(a.stats, exist_ok=True)
    hist_path = os.path.join(a.stats, "history.jsonl")
    state_path = os.path.join(a.stats, "state.json")

    snap = snapshot(games_json, a.now if a.now is not None else time.time())
    history = read_history(hist_path)
    state = load_json(state_path, {})
    alerts = check(snap, history, state, armed)

    with open(hist_path, "a") as f:
        f.write(json.dumps(snap, sort_keys=True) + "\n")
    with open(state_path, "w") as f:
        json.dump(state, f, indent=1, sort_keys=True)
    with open(os.path.join(a.stats, "latest.json"), "w") as f:
        json.dump(snap, f, indent=1, sort_keys=True)
    with open(a.alerts, "w") as f:
        for line in alerts:
            f.write(line + "\n")
    for gid, g in snap["games"].items():
        print(f"{g['title']}: views {g['views_count']}, downloads {g['downloads_count']}, purchases {g['purchases_count']}")
    print(f"armed={armed} alerts={len(alerts)}")


if __name__ == "__main__":
    main()
