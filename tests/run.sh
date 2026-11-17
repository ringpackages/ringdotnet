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
# small Windows Forms samples: each one runs itself too
for f in "$HERE"/../samples/Forms/*.ring; do
	DIR=$(dirname "$f")
	OUT=$(cd "$DIR" && timeout 120 "$RING" "$(basename "$f")" --selftest 2>&1)
	if echo "$OUT" | grep -q "SELFTEST OK" && ! echo "$OUT" | grep -q -e "Error (R" -e "rror (C" -e "^Line [0-9]* DotNet Error" -e "FAIL"; then
		echo "ok      $(basename "$f")  $(echo "$OUT" | grep SELFTEST)"
	else
		echo "FAILED  samples/Forms/$(basename "$f")"
		echo "$OUT" | head -5
		FAILED=$((FAILED+1))
	fi
done
# WPF samples
for f in "$HERE"/../samples/Wpf/*.ring; do
	DIR=$(dirname "$f")
	OUT=$(cd "$DIR" && timeout 120 "$RING" "$(basename "$f")" --selftest 2>&1)
	if echo "$OUT" | grep -q "SELFTEST OK" && ! echo "$OUT" | grep -q -e "Error (R" -e "rror (C" -e "^Line [0-9]* DotNet Error" -e "FAIL"; then
		echo "ok      wpf/$(basename "$f")  $(echo "$OUT" | grep SELFTEST)"
	else
		echo "FAILED  samples/Wpf/$(basename "$f")"
		echo "$OUT" | head -5
		FAILED=$((FAILED+1))
	fi
done
# applications: each one runs itself (--selftest) and prints SELFTEST OK
for f in "$HERE"/../applications/*/main.ring; do
	DIR=$(dirname "$f")
	OUT=$(cd "$DIR" && timeout 120 "$RING" main.ring --selftest 2>&1)
	if echo "$OUT" | grep -q "SELFTEST OK" && ! echo "$OUT" | grep -q -e "Error (R" -e "rror (C" -e "^Line [0-9]* DotNet Error" -e "FAIL"; then
		echo "ok      $(basename "$DIR")  $(echo "$OUT" | grep SELFTEST)"
	else
		echo "FAILED  application $(basename "$DIR")"
		echo "$OUT" | head -5
		FAILED=$((FAILED+1))
	fi
done
echo "$FAILED failed"
[ "$FAILED" = 0 ]
