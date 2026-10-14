#!/bin/zsh
# Samples the memory footprint of every PeaceGarden process on one simulator
# every two seconds, logs the peak, and kills the app if it passes a ceiling —
# a simulator has no jetsam, so a garden that would be killed on a phone
# instead fills the Mac's swap (13 October: 40 GB of it, and a full disk). The
# kill is recorded, and is itself a result.
#
#   zsh tools/masstest/app/watchdog.sh <udid> <log> <ceiling MB> <stop file>
#
# **The footprint, from `top`, not `ps`'s resident size.** Under memory
# pressure macOS compresses and swaps the app's pages, and the resident size
# fell to 240 MB while the footprint — what jetsam judges an app by on a phone
# — was 3 GB and climbing. Runs until the stop file exists.
set -u
SIM=$1; LOG=$2; CEILING=$3; STOP=$4
peak=0
echo "watching $SIM, ceiling $CEILING MB (footprint), $(date +%H:%M:%S)" > "$LOG"
while [[ ! -e "$STOP" ]]; do
  for pid in $(ps -axo pid=,command= | grep -e "$SIM" | grep -e "PeaceGarden.app/PeaceGarden" | grep -v -e grep | head -n 4 | awk '{print $1}'); do
    raw=$(top -l 1 -pid "$pid" -stats mem 2>/dev/null | tail -n 1 | tr -d ' +-')
    case $raw in
      *G) mb=$(( ${raw%G} * 1024 )) ;;
      *M) mb=${raw%M} ;;
      *K) mb=$(( ${raw%K} / 1024 )) ;;
      *) continue ;;
    esac
    mb=${mb%.*}
    (( $(date +%s) % 10 < 2 )) && echo "$(date +%H:%M:%S) pid $pid $mb MB" >> "$LOG"
    if (( mb > peak )); then
      peak=$mb
      echo "$(date +%H:%M:%S) pid $pid peak $mb MB" >> "$LOG"
    fi
    if (( mb > CEILING )); then
      echo "$(date +%H:%M:%S) pid $pid at $mb MB passed the ceiling: killed" >> "$LOG"
      kill -9 "$pid"
    fi
  done
  sleep 2
done
echo "stopped $(date +%H:%M:%S), peak $peak MB" >> "$LOG"
