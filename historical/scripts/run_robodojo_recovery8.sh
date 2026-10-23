#!/usr/bin/env bash
set -euo pipefail
TASK=${KINEX_TASK_ROOT}
source "$TASK/env.sh"
export ROBOENV_ASSET_CACHE="$TASK/assets"
exec 9>"$TASK/logs/robodojo-recovery7-pipeline.lock"
flock -n 9 || exit 75
STAMP=recovery8-20261021T213000Z
ASSET_LOG="$TASK/logs/robodojo-assets-recovery7-20261021T132206Z.log"
TASK_LOG="$TASK/logs/robodojo-stack-bowls-$STAMP-run.log"
RUNNER="$TASK/run_robodojo_stack_bowls_$STAMP.sh"
status() {
  python3 - "$TASK" "$1" "$$" "$ASSET_LOG" "$TASK_LOG" "$RUNNER" "${2:-}" <<'PY'
import json,sys,time
from pathlib import Path
task,phase,pid,asset_log,task_log,runner,code=sys.argv[1:]
root=Path(task);p=Path('/proc')/pid
record={'phase':phase,'pid':int(pid),'boot_id':Path('/proc/sys/kernel/random/boot_id').read_text().strip(),'start_ticks':(p/'stat').read_text().split()[21],'updated_at':time.time(),'asset_log':asset_log,'task_log':task_log,'runner':runner,'exit_code':code}
dest=root/'logs/robodojo-recovery7-pipeline.json';tmp=dest.with_suffix('.tmp');tmp.write_text(json.dumps(record,indent=2)+'\n');tmp.replace(dest)
PY
}
grep -q '"public_assets_verified": true' "$ASSET_LOG" || exit 2
cp -p "$TASK/logs/robodojo-recovery7-pipeline.json" "$TASK/logs/robodojo-recovery7-pipeline-before-$STAMP.json"
status running_stack_bowls
set +e
bash "$RUNNER" > "$TASK_LOG" 2>&1
TASK_RC=$?
set -e
status task_runner_finished "$TASK_RC"
exit "$TASK_RC"
