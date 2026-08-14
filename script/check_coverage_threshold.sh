#!/usr/bin/env bash
set -euo pipefail

THRESHOLD="${1:-80}"
REPORT_DIR="${2:-coverage-reports}"
mkdir -p "$REPORT_DIR"

echo "▶ Running forge coverage..."
forge coverage --report summary --report lcov 2>&1 | tee "$REPORT_DIR/coverage.txt"

# Convert lcov to HTML for artifact
genhtml -o "$REPORT_DIR/html" lcov.info 2>/dev/null || true
mv lcov.info "$REPORT_DIR/lcov.info"

# Parse the percentage of total coverage from forge output
COV_PCT=$(awk '/^Total/ {gsub("%","",$NF); print $NF}' "$REPORT_DIR/coverage.txt" | tail -n1)

echo "▶ Total line coverage: ${COV_PCT}%"
if (( $(echo "${COV_PCT%.*} < ${THRESHOLD}" | bc -l) )); then
  echo "✖ Coverage ${COV_PCT}% is below threshold ${THRESHOLD}%"
  exit 1
fi
echo "✓ Coverage ${COV_PCT}% meets threshold ${THRESHOLD}%"