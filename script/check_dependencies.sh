#!/usr/bin/env bash
set -euo pipefail

REPORT_DIR="${1:-security-reports}"
mkdir -p "$REPORT_DIR"

echo "▶ Installed Forge libs:"
# Use git submodule status instead of the deprecated 'forge install --list'
git submodule status 2>&1 | tee "$REPORT_DIR/forge-libs.txt"

# Known-vulnerable Solidity library versions (extend as needed)
declare -A VULN=(
  ["openzeppelin-contracts@4.4.0"]="CVE-2022-21656 (SignatureChecker)"
  ["openzeppelin-contracts@4.4.1"]="CVE-2022-21656"
  ["openzeppelin-contracts@4.4.2"]="CVE-2022-21656 / advisory OHM-01"
  ["openzeppelin-contracts@4.6.0"]="CVE-2022-31186 (ERC721CONSECUTIVE)"
  ["openzeppelin-contracts@4.7.0"]="CVE-2022-31187 (Governor)"
)

HIT=0
while IFS= read -r line; do
  for k in "${!VULN[@]}"; do
    # Check if the vulnerable version tag exists in the git submodule output
    if [[ "$line" == *"$k"* ]]; then
      echo "🚨 Vulnerable dependency: $k — ${VULN[$k]}"
      HIT=1
    fi
  done
done < "$REPORT_DIR/forge-libs.txt"

echo "$HIT" > "$REPORT_DIR/dep-scan-result.txt"
if [[ "$HIT" -eq 1 ]]; then
  echo "✖ Vulnerable dependency versions detected."
  exit 1
fi
echo "✓ No known-vulnerable dependencies detected."