#!/usr/bin/env bash
# Download the official RoboTwin archive without ever writing a transient
# response directly over the resumable payload.  Each complete HTTP range is
# appended atomically to the task-owned .partial file.
set -euo pipefail

TASK_ROOT=${KINEX_TASK_ROOT}
ASSET_DIR="$TASK_ROOT/assets/robotwin"
FINAL="$ASSET_DIR/objects.zip"
PARTIAL="$ASSET_DIR/objects.zip.partial"
URL="https://huggingface.co/datasets/TianxingChen/RoboTwin2.0/resolve/785feb15aa4a4f532395ad2b1d2be5f28cb561ad/objects.zip"
TOTAL=3737778549
CHUNK=$((16 * 1024 * 1024))
EXPECTED_SHA256=6aa56b3cf1e1064f7c809308144da36b00815f8b137fef2d7e4de856f8becf27

source "$TASK_ROOT/env.sh"
mkdir -p "$ASSET_DIR"

# Adopt an interrupted legacy download exactly once, then only append to the
# partial file.  A retry can therefore never truncate previously verified
# byte ranges.
if [[ ! -e "$PARTIAL" && -e "$FINAL" ]]; then
  mv "$FINAL" "$PARTIAL"
fi
touch "$PARTIAL"

while :; do
  offset=$(stat -c %s "$PARTIAL")
  if (( offset == TOTAL )); then
    break
  fi
  if (( offset > TOTAL )); then
    echo "partial archive exceeds expected size: $offset > $TOTAL" >&2
    exit 2
  fi

  end=$((offset + CHUNK - 1))
  if (( end >= TOTAL )); then
    end=$((TOTAL - 1))
  fi
  expected=$((end - offset + 1))
  temporary="$ASSET_DIR/.objects-${offset}-${end}.part"
  rm -f "$temporary"

  attempt=0
  until curl --fail --location --range "${offset}-${end}" \
      --connect-timeout 30 --speed-time 300 --speed-limit 1024 \
      --retry 0 --output "$temporary" "$URL"; do
    attempt=$((attempt + 1))
    rm -f "$temporary"
    delay=$((attempt < 12 ? attempt * 5 : 60))
    echo "range ${offset}-${end} failed (attempt ${attempt}); retrying in ${delay}s" >&2
    sleep "$delay"
  done

  actual=$(stat -c %s "$temporary")
  if (( actual != expected )); then
    rm -f "$temporary"
    echo "range ${offset}-${end} returned ${actual} bytes; expected ${expected}; retrying" >&2
    sleep 10
    continue
  fi

  cat "$temporary" >> "$PARTIAL"
  rm -f "$temporary"
  sync "$PARTIAL"
  printf 'range committed: %s-%s (%s/%s bytes)\n' "$offset" "$end" "$(stat -c %s "$PARTIAL")" "$TOTAL"
done

actual_sha256=$(sha256sum "$PARTIAL" | awk '{print $1}')
if [[ "$actual_sha256" != "$EXPECTED_SHA256" ]]; then
  echo "archive SHA-256 mismatch: $actual_sha256" >&2
  exit 3
fi
mv "$PARTIAL" "$FINAL"
printf 'SHA-256 verified: %s\n' "$actual_sha256"
