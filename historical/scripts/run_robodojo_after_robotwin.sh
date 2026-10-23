#!/usr/bin/env bash
set -euo pipefail

TASK_ROOT=${KINEX_TASK_ROOT}
ROBOENV_ROOT="$TASK_ROOT/RoboEnv"
LOG="$TASK_ROOT/logs/prepare-robodojo.log"

while tmux has-session -t kinex-robotwin-pipeline 2>/dev/null; do
  sleep 10
done

# These are task-owned, recreated by `roboenv prepare`, and no longer needed
# after the RoboTwin terminal evidence and recordings have been retained.
rm -rf \
  "$ROBOENV_ROOT/.venv-sim/robotwin" \
  "$ROBOENV_ROOT/.venv-sim/robotwin-retry" \
  "$ROBOENV_ROOT/third_party/RoboTwin" \
  "$TASK_ROOT/assets/robotwin"

source "$TASK_ROOT/env.sh"
export ROBOENV_ASSET_CACHE="$TASK_ROOT/assets"
export UV_HTTP_TIMEOUT=120
export UV_HTTP_RETRIES=5
cd "$ROBOENV_ROOT"
.venv/bin/roboenv prepare robodojo --prefix .venv-sim/robodojo --json > "$LOG" 2>&1
"$TASK_ROOT/run_robodojo_stack_bowls.sh"
