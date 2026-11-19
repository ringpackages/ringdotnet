#!/bin/sh
# Runs the RingDotNet tests (samples/UsingDotNet/tests/test_*.ring) and the non-interactive samples; fails on any error.
# Usage: samples/UsingDotNet/tests/run.sh [path to ring] [--quick] [--jobs N] [--show]     (the package bin folder is added to the PATH)
#   --quick    only the tests and the introduction samples (about 20 seconds); without it everything runs (a few minutes)
#   --jobs N   run N programs at the same time (default 4, 1 = one after the other)
#   --show     do not hide the windows of the programs that run themselves (they are invisible and not in the taskbar by default)
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/../../.."
RING=ring
QUICK=0
JOBS=4
NEXTJOBS=0
for ARG in "$@"; do
	if [ "$NEXTJOBS" = "1" ]; then JOBS="$ARG"; NEXTJOBS=0; continue; fi
	case "$ARG" in
		--quick) QUICK=1 ;;
		--jobs) NEXTJOBS=1 ;;
		--show) RINGDOTNET_SHOW=1; export RINGDOTNET_SHOW ;;
		*) RING="$ARG" ;;
	esac
done
START=$(date +%s)
unset RING_HOME
PATH="$ROOT/bin:$PATH"
export RING
LIST=$(mktemp)
RESULT=$(mktemp)
trap 'rm -f "$LIST" "$RESULT"' EXIT

# a group of programs: they run JOBS at a time and every result is printed as soon as the program ends
# (the programs that use the clipboard or type keys run one after the other at the end of the group: the clipboard belongs to the whole desktop,
# and keys go through the message loop of Windows, which does not like many windows at once)
rungroup() {
	SERIAL=$(mktemp)
	PARALLEL=$(mktemp)
	while IFS='|' read -r KIND DIR FILE LABEL; do
		if [ "$FILE" = "main.ring" ]; then USES=$(grep -rlE "Clipboard|uiSendKeys|uiGameKeys|uiInputKeys" "$DIR" 2>/dev/null); else USES=$(grep -lE "Clipboard|uiSendKeys|uiGameKeys|uiInputKeys" "$DIR/$FILE" 2>/dev/null); fi
		if [ -n "$USES" ]; then echo "$KIND|$DIR|$FILE|$LABEL" >> "$SERIAL"; else echo "$KIND|$DIR|$FILE|$LABEL" >> "$PARALLEL"; fi
	done < "$LIST"
	xargs -P "$JOBS" -I{} sh "$HERE/runone.sh" "{}" < "$PARALLEL" | tee -a "$RESULT"
	xargs -P 1 -I{} sh "$HERE/runone.sh" "{}" < "$SERIAL" | tee -a "$RESULT"
	rm -f "$SERIAL" "$PARALLEL"
	: > "$LIST"
}

# 1. the tests and the introduction samples
for f in "$HERE"/test_*.ring; do echo "t|$HERE|$(basename "$f")|$(basename "$f")" >> "$LIST"; done
for f in "$HERE"/../introduction/test*.ring; do echo "t|$HERE/../introduction|$(basename "$f")|$(basename "$f")" >> "$LIST"; done
rungroup

if [ "$QUICK" = "0" ]; then
	# 2. tutorials: the ones with a window test run themselves (--selftest), the others just have to run without an error
	for f in "$HERE"/../tutorials/*.ring; do
		[ -f "$f" ] || continue
		if [ -f "$(dirname "$f")/selftest/$(basename "$f")" ] || grep -q -e "uiTest(" -e "wpfTest(" -e "wpfSelfTest()" "$f"; then KIND=s; else KIND=n; fi
		echo "$KIND|$HERE/../tutorials|$(basename "$f")|tutorial $(basename "$f")" >> "$LIST"
	done
	rungroup

	# 3. samples and applications with a window: each one runs itself (--selftest) and prints SELFTEST OK
	for f in "$HERE"/../Forms/*.ring; do echo "s|$HERE/../Forms|$(basename "$f")|samples/UsingDotNet/Forms/$(basename "$f")" >> "$LIST"; done
	for f in "$HERE"/../Wpf/*.ring; do echo "s|$HERE/../Wpf|$(basename "$f")|samples/UsingDotNet/Wpf/$(basename "$f")" >> "$LIST"; done
	for f in "$HERE"/../applications/*/main.ring; do echo "s|$(dirname "$f")|main.ring|application $(basename "$(dirname "$f")")" >> "$LIST"; done
	rungroup
fi

FAILED=$(grep -c '^FAILED' "$RESULT")
if [ "$QUICK" = "1" ]; then
	echo "$FAILED failed (quick: tests and introduction samples only, $(( $(date +%s) - START )) seconds)"
else
	echo "$FAILED failed ($(( $(date +%s) - START )) seconds)"
fi
[ "$FAILED" = "0" ]
