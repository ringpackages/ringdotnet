#!/bin/sh
# Runs one program for run.sh and prints its result (one block, so that parallel runs do not mix their lines).
# Usage: runone.sh "kind|directory|file|label"        (the environment variable RING is the ring program)
#   kind t   a test or an introduction sample: it must not print an error or a FAIL: line
#   kind s   a program that runs itself with --selftest and must print SELFTEST OK
#   kind n   a tutorial without a window: it must run without an error
IFS='|' read -r KIND DIR FILE LABEL <<EOF
$1
EOF
case "$KIND" in
	t)
		OUT=$(cd "$DIR" && timeout 180 "$RING" "$FILE" 2>&1)
		if echo "$OUT" | grep -q -e "Error (R" -e "rror (C" -e "^Line [0-9]* DotNet Error" -e "Fatal" -e "FAIL:" -e "[1-9][0-9]* failed"; then
			printf '%s\n' "FAILED  $LABEL" "$(echo "$OUT" | grep -e "rror" -e "Fatal" -e "FAIL" | head -5)"
		else
			printf '%s\n' "ok      $LABEL  $(echo "$OUT" | grep '^TESTS:')"
		fi
		;;
	s)
		OUT=$(cd "$DIR" && timeout 120 "$RING" "$FILE" --selftest 2>&1)
		RETRY=""
		# Windows can fail to create a window when many windows are created at once (Win32Exception): try that program once more
		if echo "$OUT" | grep -q "Win32Exception"; then
			sleep 2
			OUT=$(cd "$DIR" && timeout 120 "$RING" "$FILE" --selftest 2>&1)
			RETRY=" (second try: the system could not create a window the first time)"
		fi
		if echo "$OUT" | grep -q "SELFTEST OK" && ! echo "$OUT" | grep -q -e "Error (R" -e "rror (C" -e "^Line [0-9]* DotNet Error" -e "FAIL"; then
			printf '%s\n' "ok      $LABEL  $(echo "$OUT" | grep SELFTEST)$RETRY"
		else
			printf '%s\n' "FAILED  $LABEL" "$(echo "$OUT" | head -5)"
		fi
		;;
	n)
		OUT=$(cd "$DIR" && timeout 180 "$RING" "$FILE" 2>&1)
		if echo "$OUT" | grep -q -e "Error (R" -e "rror (C" -e "^Line [0-9]* DotNet Error" -e "FAIL:"; then
			printf '%s\n' "FAILED  $LABEL" "$(echo "$OUT" | head -5)"
		else
			printf '%s\n' "ok      $LABEL"
		fi
		;;
esac
