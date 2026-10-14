#!/bin/sh
# One Xcode build or test at a time on this Mac (Marcus, 14 Oct 2026: parallel builds stalled the machine).
# Usage: sh xcode-lock.sh <command...>   e.g. sh xcode-lock.sh xcodebuild test -jobs 4 ...
L=/private/tmp/claude-501/xcode.lock
until mkdir "$L" 2>/dev/null; do
  # A holder that died leaves its pid behind; take the lock over if that process is gone.
  p=$(head -n 1 "$L/pid" 2>/dev/null)
  if [ -n "$p" ] && ! kill -0 "$p" 2>/dev/null; then rm -rf "$L"; continue; fi
  sleep 15
done
echo $$ > "$L/pid"
trap 'rm -rf "$L"' EXIT INT TERM
"$@"
