#!/usr/bin/env bash
set -euo pipefail

TASK_ROOT=${KINEX_TASK_ROOT}
EXPECTED_SHA256=6aa56b3cf1e1064f7c809308144da36b00815f8b137fef2d7e4de856f8becf27

while tmux has-session -t kinex-download-robotwin-objects 2>/dev/null; do
  sleep 10
done

actual=$(sha256sum "$TASK_ROOT/assets/robotwin/objects.zip" | awk '{print $1}')
[[ "$actual" == "$EXPECTED_SHA256" ]]

source "$TASK_ROOT/env.sh"
export ROBOENV_ASSET_CACHE="$TASK_ROOT/assets"
export UV_HTTP_TIMEOUT=120
export UV_HTTP_RETRIES=5
cd "$TASK_ROOT/RoboEnv"
.venv/bin/roboenv prepare robotwin --json
"$TASK_ROOT/run_robotwin_handover.sh"
