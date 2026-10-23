#!/usr/bin/env bash
set -euo pipefail

source "${KINEX_TASK_ROOT:?Set KINEX_TASK_ROOT}/env.sh"
export ROBOENV_ASSET_CACHE="$KINEX_TASK_ROOT/assets"
export UV_HTTP_TIMEOUT=120
export UV_HTTP_RETRIES=5

ROBOENV_ROOT="$KINEX_TASK_ROOT/RoboEnv"
WORKSPACE="$KINEX_TASK_ROOT/workspaces/robotwin-handover-block"
PORT=8124
RECORDING="$KINEX_TASK_ROOT/recordings/robotwin-handover-block-retry3"
LAUNCH_RECORD="$KINEX_TASK_ROOT/logs/robotwin-handover-retry3-launch.json"
AGENT_LOG="$KINEX_TASK_ROOT/logs/robotwin-handover-kinex-retry3.jsonl"
export NODE_OPTIONS="--import=$KINEX_TASK_ROOT/network-diagnostics.mjs${NODE_OPTIONS:+ $NODE_OPTIONS}"

cd "$ROBOENV_ROOT"
.venv/bin/roboenv doctor robotwin --json > "$KINEX_TASK_ROOT/logs/robotwin-retry3-doctor.json"
python3 - "$KINEX_TASK_ROOT/logs/robotwin-retry3-doctor.json" <<'PY'
import json
import sys

report = json.load(open(sys.argv[1]))
if not report.get("installed") or not report.get("install_preflight_passed"):
    raise SystemExit("RoboTwin is not ready for a task run")
PY

mkdir -p "$WORKSPACE"
if [[ ! -d "$WORKSPACE/.kinex" ]]; then
  (
    cd "$WORKSPACE"
    "$ROBOENV_ROOT/.venv/bin/roboenv" setup robotwin/robotwin-aloha-agilex
  )
fi

uv pip install --python "$WORKSPACE/.kinex/python/.venv/bin/python3" pyyaml==6.0.3

rm -f "$LAUNCH_RECORD"
.venv/bin/roboenv launch robotwin/handover-block-aloha-agilex \
  --port "$PORT" \
  --record "$RECORDING" \
  --stop-on-success \
  --detach \
  --json > "$LAUNCH_RECORD"

for _ in $(seq 1 60); do
  if .venv/bin/roboenv status --port "$PORT" --json >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

export ROBOENV_ENDPOINT="http://127.0.0.1:$PORT"
cd "$WORKSPACE"
set +e
timeout 2100 kinex \
  --auto \
  --provider openai-codex \
  --model gpt-6.1-sol \
  --thinking high \
  --mode json \
  -p 'Operate the currently running RoboTwin simulator through Kinex only. The task is: use the left arm to grasp the red block on the table, hand it over to the right arm, and set it down in the center of the blue pad. Release it with the right gripper open. Begin by checking the available devices and loading/pinging any that are not ready. Inspect camera observations and robot state, then use Kinex device tools to perform the task carefully. Do not use shell commands or call the RoboEnv driver directly. Verify the final state through Kinex observations; report what happened honestly.' \
  > "$AGENT_LOG" 2>&1
AGENT_EXIT=$?
set -e

RUN_ID=$(python3 - "$LAUNCH_RECORD" <<'PY'
import json
import sys
data = json.load(open(sys.argv[1]))
for key in ("id", "run", "session"):
    if key in data:
        print(data[key])
        break
else:
    raise SystemExit("No run identifier in launch result")
PY
)

"$ROBOENV_ROOT/.venv/bin/roboenv" stop "$RUN_ID" --json > "$KINEX_TASK_ROOT/logs/robotwin-handover-retry3-stopped.json" || true
printf 'EXIT=%s\n' "$AGENT_EXIT" >> "$AGENT_LOG"
exit "$AGENT_EXIT"
