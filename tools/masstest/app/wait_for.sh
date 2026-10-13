#!/bin/zsh
# Blocks until every clock file named has a DONE line, or the time is up.
#
#   zsh tools/masstest/app/wait_for.sh <seconds> <clock> [<clock> ...]
set -u
cd "${0:A:h}/../../.."
LIMIT=$1; shift
start=$(date +%s)
while (( $(date +%s) - start < LIMIT )); do
  done_all=1
  for clock in "$@"; do
    [[ -e "$clock" ]] && [[ "$(tail -n 1 "$clock")" == DONE ]] || done_all=0
  done
  (( done_all )) && break
  sleep 10
done
date +%H:%M:%S
for clock in "$@"; do
  echo "== $clock"
  head -n 12 "$clock"
done
