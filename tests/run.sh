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
for f in "$HERE"/../samples/UsingDotNet/introduction/test*.ring; do run "$HERE/../samples/UsingDotNet/introduction" "$(basename "$f")"; done
# small Windows Forms samples: each one runs itself too
for f in "$HERE"/../samples/UsingDotNet/Forms/*.ring; do
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
for f in "$HERE"/../samples/UsingDotNet/Wpf/*.ring; do
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
for f in "$HERE"/../samples/UsingDotNet/applications/*/main.ring; do
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
for f in "$HERE"/../docs/tutorials/*.ring; do
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
