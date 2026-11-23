#!/bin/sh
# Captures a screenshot of every GUI sample and application: docs/img/shots/<kind>-<name>.png
HERE="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$HERE/.."
WIN() { cygpath -w "$1"; }
shot() { # dir script out
	powershell -NoProfile -ExecutionPolicy Bypass -File "$(WIN "$HERE/tools/shot.ps1")" -Dir "$(WIN "$1")" -Script "$2" -Out "$(WIN "$3")" -Delay "${4:-2500}" 2>&1 | tail -1
}
for f in "$ROOT"/samples/UsingDotNet/Forms/*.ring; do n=$(basename "$f" .ring); shot "$ROOT/samples/UsingDotNet/Forms" "$n.ring" "$HERE/img/shots/forms-$n.png"; done
for f in "$ROOT"/samples/UsingDotNet/Wpf/*.ring; do n=$(basename "$f" .ring); shot "$ROOT/samples/UsingDotNet/Wpf" "$n.ring" "$HERE/img/shots/wpf-$n.png" 3500; done
for d in "$ROOT"/samples/UsingDotNet/applications/*/; do n=$(basename "$d"); case "$n" in WebApi|Contacts) continue;; esac
	f="$n.ring"
	if grep -q "dnUseDesktop" "$d/$f"; then shot "$d" "$f" "$HERE/img/shots/app-$n.png" 3500; fi; done
