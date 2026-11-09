#!/usr/bin/env bash
# Run the 30-day soak test on several seeds (2 at a time) and print one line per seed.
#   tools/soak.sh            # seeds 1 2 3 + seed 4 lazy
#   tools/soak.sh 7 8        # just these seeds
#   DAYS=10 tools/soak.sh 1  # shorter run
# Logs: $SOAK_OUT (default /tmp/soak)/seed_<n>.log. Exit 1 if any seed fails. Never touches the real save.
set -u
cd "$(dirname "$0")/.."
GODOT=${GODOT:-godot}
DAYS=${DAYS:-30}
export XDG_DATA_HOME=${XDG_DATA_HOME:-/tmp/xdg_soak}
OUT=${SOAK_OUT:-/tmp/soak}
mkdir -p "$OUT"
runs=("$@")
[ ${#runs[@]} -eq 0 ] && runs=(1 2 3 4:lazy)
run() {
	local s=${1%%:*} extra=""
	[[ "$1" == *:lazy ]] && extra="--lazy"
	"$GODOT" --headless --path . --fixed-fps 30 --script tools/soak.gd -- --seed="$s" --days="$DAYS" $extra > "$OUT/seed_$1.log" 2>&1
}
pids=()
for r in "${runs[@]}"; do
	run "$r" &
	pids+=($!)
	if [ ${#pids[@]} -ge 2 ]; then wait "${pids[0]}"; pids=("${pids[@]:1}"); fi
done
wait
fail=0
for r in "${runs[@]}"; do
	f="$OUT/seed_$r.log"
	res=$(grep -E "^SOAK (PASS|FAIL)" "$f" || echo "SOAK CRASH (no report)")
	errs=$(grep -cE "SCRIPT ERROR|^ERROR" "$f")
	echo "seed $r: $res, $(grep -m1 'days completed' "$f"), $errs engine error lines, $(grep -c '^ISSUE' "$f") issues  ($f)"
	[[ "$res" == *PASS* ]] || fail=1
done
exit $fail
