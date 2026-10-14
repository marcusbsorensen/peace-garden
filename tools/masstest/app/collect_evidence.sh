#!/bin/zsh
# Copies the small, durable results of a run (stress JSON, watchdog logs, the
# fuzz summary) from build/mt into the report's evidence folder.
#
#   zsh tools/masstest/app/collect_evidence.sh design/mass-test-2026-10-13/app/evidence
set -u
cd "${0:A:h}/../../.."
EVIDENCE=${1:?evidence folder}
mkdir -p "$EVIDENCE/stress"
for d in build/mt/stress-*(N/); do
  name=${d:t}
  mkdir -p "$EVIDENCE/stress/$name"
  cp "$d"/stress-*.json "$d"/stress-log.txt "$EVIDENCE/stress/$name/" 2>/dev/null
done
[[ -e build/mt/watchdog-stress.log ]] && cp build/mt/watchdog-stress.log "$EVIDENCE/stress/watchdog-unoptimised-rss.log"
[[ -e build/mt/watchdog-stress-O3.log ]] && cp build/mt/watchdog-stress-O3.log "$EVIDENCE/stress/watchdog-optimised-footprint.log"
[[ -e build/mt/fuzz/run1/fuzz-summary.json ]] && cp build/mt/fuzz/run1/fuzz-summary.json "$EVIDENCE/fuzz-summary.json"
[[ -e build/mt/fuzz/check.log ]] && cp build/mt/fuzz/check.log "$EVIDENCE/fuzz-check.log"
for f in build/mt/perf/perf-*.json build/mt/perf/metrics-*.json(N); do
  mkdir -p "$EVIDENCE/perf"
  cp "$f" "$EVIDENCE/perf/"
done
du -sh "$EVIDENCE"
