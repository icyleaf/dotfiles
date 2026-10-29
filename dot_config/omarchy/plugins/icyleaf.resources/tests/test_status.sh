#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATUS_SCRIPT="${SCRIPT_DIR}/../status.sh"

echo "=== Testing status.sh output and performance ==="

# 1. Capture output and stderr
STDERR_FILE="$(mktemp)"
trap 'rm -f "$STDERR_FILE"' EXIT

START_TIME=$(date +%s%N)
OUTPUT="$("$STATUS_SCRIPT" "/" 2>"$STDERR_FILE")"
END_TIME=$(date +%s%N)

ELAPSED_MS=$(( (END_TIME - START_TIME) / 1000000 ))
echo "Execution time: ${ELAPSED_MS} ms"

# 2. Check stderr is clean (no I/O errors or command failures)
STDERR_CONTENT="$(cat "$STDERR_FILE")"
if [ -n "$STDERR_CONTENT" ]; then
  echo "FAIL: Stderr was not empty:"
  echo "$STDERR_CONTENT"
  exit 1
fi

# 3. Check all required lines exist
for key in host cpu memory load disk gpu cpu_detail temps fans; do
  if ! echo "$OUTPUT" | grep -q "^${key}[[:space:]]"; then
    echo "FAIL: Missing metric line '${key}'"
    exit 1
  fi
done

# 4. Check JSON valid for temps and fans
TEMPS_JSON=$(echo "$OUTPUT" | awk -F'\t' '$1 == "temps" {print $2}')
if ! echo "$TEMPS_JSON" | jq . >/dev/null 2>&1; then
  echo "FAIL: Invalid temps JSON: $TEMPS_JSON"
  exit 1
fi

FANS_JSON=$(echo "$OUTPUT" | awk -F'\t' '$1 == "fans" {print $2}')
if ! echo "$FANS_JSON" | jq . >/dev/null 2>&1; then
  echo "FAIL: Invalid fans JSON: $FANS_JSON"
  exit 1
fi

# 5. Performance threshold: must complete in < 150 ms
MAX_ALLOWED_MS=150
if [ "$ELAPSED_MS" -gt "$MAX_ALLOWED_MS" ]; then
  echo "FAIL: Execution time ${ELAPSED_MS}ms exceeded limit of ${MAX_ALLOWED_MS}ms"
  exit 1
fi

echo "PASS: status.sh completed in ${ELAPSED_MS}ms with valid metrics and clean stderr."
