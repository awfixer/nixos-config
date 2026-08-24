#!/usr/bin/env bash
# Print RSS (kB) for a running tyyt process.
set -euo pipefail
pid=$(pidof tyyt 2>/dev/null | awk '{print $1}') || {
  echo "tyyt is not running" >&2
  exit 1
}
rss_kb=$(ps -o rss= -p "$pid" | tr -d ' ')
echo "pid=$pid rss_kb=$rss_kb rss_mb=$(awk -v k="$rss_kb" 'BEGIN{printf "%.1f", k/1024}')"
