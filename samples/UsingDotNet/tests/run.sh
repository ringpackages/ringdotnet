#!/bin/sh
# Runs the RingDotNet tests (samples/UsingDotNet/tests/test_*.ring) and the non-interactive samples; fails on any error.
# Usage: samples/UsingDotNet/tests/run.sh [path to ring] [--quick]     (needs ring.dll on the PATH; the package bin folder is added)
#   --quick   only the tests and the introduction samples (about a minute); without it everything runs (about ten minutes)
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/../../.."
RING=ring
QUICK=0
for ARG in "$@"; do
	if [ "$ARG" = "--quick" ]; then QUICK=1; else RING="$ARG"; fi
done
START=$(date +%s)
unset RING_HOME
PATH="$ROOT/bin:$PATH"
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
for f in "$HERE"/../introduction/test*.ring; do run "$HERE/../introduction" "$(basename "$f")"; done
if [ "$QUICK" = "1" ]; then
	echo "$FAILED failed (quick: tests and introduction samples only, $(( $(date +%s) - START )) seconds)"
	[ "$FAILED" = "0" ]
	exit $?
fi
# small Windows Forms samples: each one runs itself too
for f in "$HERE"/../Forms/*.ring; do
	DIR=$(dirname "$f")
	OUT=$(cd "$DIR" && timeout 120 "$RING" "$(basename "$f")" --selftest 2>&1)
	if echo "$OUT" | grep -q "SELFTEST OK" && ! echo "$OUT" | grep -q -e "Error (R" -e "rror (C" -e "^Line [0-9]* DotNet Error" -e "FAIL"; then
		echo "ok      $(basename "$f")  $(echo "$OUT" | grep SELFTEST)"
	else
		echo "FAILED  samples/UsingDotNet/Forms/$(basename "$f")"
		echo "$OUT" | head -5
		FAILED=$((FAILED+1))
	fi
done
# WPF samples
for f in "$HERE"/../Wpf/*.ring; do
	DIR=$(dirname "$f")
	OUT=$(cd "$DIR" && timeout 120 "$RING" "$(basename "$f")" --selftest 2>&1)
	if echo "$OUT" | grep -q "SELFTEST OK" && ! echo "$OUT" | grep -q -e "Error (R" -e "rror (C" -e "^Line [0-9]* DotNet Error" -e "FAIL"; then
		echo "ok      wpf/$(basename "$f")  $(echo "$OUT" | grep SELFTEST)"
	else
		echo "FAILED  samples/UsingDotNet/Wpf/$(basename "$f")"
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
# tutorials (docs/tutorials): programs with a window test (uiTest/wpfTest) run themselves (--selftest), the others just have to run without an error
for f in "$ROOT"/docs/tutorials/*.ring; do
	DIR=$(dirname "$f")
	if grep -q -e "uiTest(" -e "wpfTest(" "$f"; then
		OUT=$(cd "$DIR" && timeout 120 "$RING" "$(basename "$f")" --selftest 2>&1)
		if echo "$OUT" | grep -q "SELFTEST OK" && ! echo "$OUT" | grep -q -e "Error (R" -e "rror (C" -e "FAIL"; then
			echo "ok      tutorial $(basename "$f")"
		else
			echo "FAILED  tutorial $(basename "$f")"
			echo "$OUT" | head -5
			FAILED=$((FAILED+1))
		fi
	else
		OUT=$(cd "$DIR" && timeout 180 "$RING" "$(basename "$f")" 2>&1)
		if echo "$OUT" | grep -q -e "Error (R" -e "rror (C" -e "^Line [0-9]* DotNet Error" -e "FAIL:"; then
			echo "FAILED  tutorial $(basename "$f")"
			echo "$OUT" | head -5
			FAILED=$((FAILED+1))
		else
			echo "ok      tutorial $(basename "$f")"
		fi
	fi
done
echo "$FAILED failed"
[ "$FAILED" = 0 ]
