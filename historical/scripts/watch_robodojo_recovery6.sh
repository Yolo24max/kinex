#!/usr/bin/env bash
set -euo pipefail
TASK=${KINEX_TASK_ROOT}
source "$TASK/env.sh"
export ROBOENV_ASSET_CACHE="$TASK/assets"
cd "$TASK/RoboEnv"
ASSET_PID=450499
ASSET_LOG="$TASK/logs/robodojo-assets-recovery6b-20261021.log"
STATUS="$TASK/logs/robodojo-recovery6-watcher.status"
TASK_LOG="$TASK/logs/robodojo-stack-bowls-recovery6-run.log"
printf '%s waiting for asset process %s\n' "$(date -u +%FT%TZ)" "$ASSET_PID" > "$STATUS"
while kill -0 "$ASSET_PID" 2>/dev/null; do sleep 30; done
if ! grep -q '"public_assets_verified": true' "$ASSET_LOG" 2>/dev/null; then
  success=0
  for attempt in 1 2 3 4; do
    out="$TASK/logs/robodojo-assets-recovery6-retry${attempt}-20261021.log"
    printf '%s asset retry %s starting\n' "$(date -u +%FT%TZ)" "$attempt" >> "$STATUS"
    if .venv/bin/python src/roboenv/provisioning/robodojo_assets.py --project "$TASK/RoboEnv" --cache "$TASK/assets/robodojo" > "$out" 2>&1 && grep -q '"public_assets_verified": true' "$out"; then success=1; break; fi
    sleep $((attempt * 20))
  done
  if [[ "$success" != 1 ]]; then echo "asset prep failed after resumable retries" >> "$STATUS"; exit 2; fi
fi
echo "$(date -u +%FT%TZ) assets verified; starting official stack-bowls task" >> "$STATUS"
.venv/bin/roboenv doctor robodojo --json > "$TASK/logs/robodojo-doctor-recovery6.json"
python3 - "$TASK/logs/robodojo-doctor-recovery6.json" <<'PY'
import json,sys
p=json.load(open(sys.argv[1]))
if not p.get("installed") or not p.get("install_preflight_passed"):
    raise SystemExit("RoboDojo installation doctor check failed")
PY
"$TASK/run_robodojo_stack_bowls_recovery6.sh" > "$TASK_LOG" 2>&1
rc=$?
echo "$(date -u +%FT%TZ) task runner exited $rc" >> "$STATUS"
exit "$rc"
