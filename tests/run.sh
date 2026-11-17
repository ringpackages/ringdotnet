#!/bin/sh
# Runs the RingDotNet tests (tests/test_*.ring) and the non-interactive samples; fails on any error.
# Usage: tests/run.sh [path to ring]     (needs ring.dll on the PATH; the package bin folder is added)
HERE="$(cd "$(dirname "$0")" && pwd)"
RING="${1:-ring}"
unset RING_HOME
PATH="$HERE/../bin:$PATH"
FAILED=0
run() {
	OUT=$(cd "$1" && timeout 180 "$RING" "$2" 2>&1)
	if echo "$OUT" | grep -q -e "Error (R" -e "rror (C" -e "^Line [0-9]* DotNet Error" -e "Fatal" -e "FAIL:" -e "[1-9][0-9]* failed"; then
		echo "FAILED  $2"
		echo "$OUT" | grep -e "rror" -e "Fatal" -e "FAIL" | head -5
		FAILED=$((FAILED+1))
	else
		echo "ok      $2  $(echo "$OUT" | grep '^TESTS:')"
	fi
}
for f in "$HERE"/test_*.ring; do run "$HERE" "$(basename "$f")"; done
for f in "$HERE"/../samples/UsingDotNet/test*.ring; do run "$HERE/../samples/UsingDotNet" "$(basename "$f")"; done
echo "$FAILED failed"
[ "$FAILED" = 0 ]
