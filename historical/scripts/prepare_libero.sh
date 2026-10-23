#!/usr/bin/env bash
set -euo pipefail
source "${KINEX_TASK_ROOT:?Set KINEX_TASK_ROOT}/env.sh"
exec > >(tee -a "$KINEX_TASK_ROOT/logs/prepare-libero.log") 2>&1
cd "$KINEX_TASK_ROOT/RoboEnv"
.venv/bin/roboenv prepare libero --json > "$KINEX_TASK_ROOT/libero-prepare.json"
.venv/bin/roboenv doctor libero --json > "$KINEX_TASK_ROOT/libero-doctor.json"
.venv/bin/roboenv sources status --backends libero > "$KINEX_TASK_ROOT/libero-sources-status.txt"
mkdir -p "$KINEX_TASK_ROOT/workspaces/libero-spatial-03"
cd "$KINEX_TASK_ROOT/workspaces/libero-spatial-03"
"$KINEX_TASK_ROOT/RoboEnv/.venv/bin/roboenv" setup libero/libero-panda-tabletop
echo LIBERO_PREPARATION_COMPLETE
