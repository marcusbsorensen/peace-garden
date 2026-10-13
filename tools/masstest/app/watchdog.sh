#!/bin/zsh
# Samples the resident memory of every PeaceGarden process on one simulator
# once a second, logs the peak, and kills the app if it passes a ceiling — a
# simulator has no jetsam, so a garden that would be killed on a phone instead
# eats the Mac. The kill is recorded, and is itself a result.
#
#   zsh tools/masstest/app/watchdog.sh <udid> <log> <ceiling MB> <stop file>
#
# Runs until the stop file exists.
set -u
SIM=$1; LOG=$2; CEILING=$3; STOP=$4
peak=0
echo "watching $SIM, ceiling $CEILING MB, $(date +%H:%M:%S)" > "$LOG"
while [[ ! -e "$STOP" ]]; do
  ps -axo pid=,rss=,command= | grep -e "$SIM" | grep -e "PeaceGarden.app/PeaceGarden" | grep -v -e grep | head -n 4 | while read -r pid rss rest; do
    mb=$(( rss / 1024 ))
    if (( mb > peak )); then
      peak=$mb
      echo "$(date +%H:%M:%S) pid $pid peak $mb MB" >> "$LOG"
    fi
    if (( mb > CEILING )); then
      echo "$(date +%H:%M:%S) pid $pid at $mb MB passed the ceiling: killed" >> "$LOG"
      kill -9 "$pid"
    fi
  done
  sleep 1
done
echo "stopped $(date +%H:%M:%S), peak $peak MB" >> "$LOG"
