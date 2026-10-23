#!/usr/bin/env bash
set -euo pipefail

source "${KINEX_TASK_ROOT:?Set KINEX_TASK_ROOT}/env.sh"
export ROBOENV_ASSET_CACHE="$KINEX_TASK_ROOT/assets"
export LD_LIBRARY_PATH="$KINEX_TASK_ROOT/runtime-libs/root/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"

ROBOENV_ROOT="$KINEX_TASK_ROOT/RoboEnv"
WORKSPACE="$KINEX_TASK_ROOT/workspaces/robodojo-stack-bowls"
PORT=8125
RECORDING="$KINEX_TASK_ROOT/recordings/robodojo-stack-bowls-recovery10-20261022T030720Z"
LAUNCH_RECORD="$KINEX_TASK_ROOT/logs/robodojo-stack-bowls-recovery10-20261022T030720Z-launch.json"
AGENT_LOG="$KINEX_TASK_ROOT/logs/robodojo-stack-bowls-recovery10-20261022T030720Z-kinex.jsonl"
export NODE_OPTIONS="--import=$KINEX_TASK_ROOT/network-diagnostics.mjs${NODE_OPTIONS:+ $NODE_OPTIONS}"

cd "$ROBOENV_ROOT"
.venv/bin/roboenv doctor robodojo --json > "$KINEX_TASK_ROOT/logs/robodojo-doctor-recovery10-20261022T030720Z.json"
python3 - "$KINEX_TASK_ROOT/logs/robodojo-doctor-recovery10-20261022T030720Z.json" <<'PY'
import json
import sys

report = json.load(open(sys.argv[1]))
if not report.get("installed") or not report.get("install_preflight_passed"):
    raise SystemExit("RoboDojo is not ready for a task run")
PY

mkdir -p "$WORKSPACE"
if [[ ! -d "$WORKSPACE/.kinex" ]]; then
  (
    cd "$WORKSPACE"
    "$ROBOENV_ROOT/.venv/bin/roboenv" setup robodojo/robodojo-arx-x5
  )
fi

node --input-type=module - "$KINEX_TASK_ROOT" "$WORKSPACE" <<'JS'
const root=process.argv[2], workspace=process.argv[3];
const {initializePython}=await import(root+"/kinex-data/install/node_modules/@kinex/core/dist/python/environment.js");
const runtime=await initializePython(workspace);
console.log("Initialized task Python project:",runtime.project);
JS
uv sync --project "$WORKSPACE/.kinex/python" --python "$KINEX_TASK_ROOT/workspaces/robotwin-handover-block/.kinex/python/.venv/bin/python3"

uv pip install --python "$WORKSPACE/.kinex/python/.venv/bin/python3" \
  pyyaml==6.0.3 numpy==2.5.4 scipy==1.18.1

.venv/bin/roboenv launch robodojo/stack-bowls \
  --port "$PORT" \
  --record "$RECORDING" \
  --stop-on-success \
  --detach \
  --json > "$LAUNCH_RECORD"

for _ in $(seq 1 90); do
  if .venv/bin/roboenv status --port "$PORT" --json >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

export ROBOENV_ENDPOINT="http://127.0.0.1:$PORT"
cd "$WORKSPACE"
set +e
timeout 3000 kinex \
  --auto \
  --provider openai-codex \
  --model gpt-6.1-sol \
  --thinking high \
  --mode json \
  -p 'Operate the currently running RoboDojo simulator through Kinex only. The task is: stack the three bowls into one centered, nested stack with their openings facing up, then return both arms to their starting poses. Begin by checking the available devices and loading/pinging any that are not ready. Inspect camera observations and robot state, then use Kinex device tools to perform the task carefully. Do not use shell commands or call the RoboEnv driver directly. Verify the final state through Kinex observations; report what happened honestly.' \
  > "$AGENT_LOG" 2>&1
AGENT_EXIT=$?
set -e

AGENT_EXIT=$(python3 - "$AGENT_LOG" "$AGENT_EXIT" <<'PYOUTCOME'
import json,sys
from pathlib import Path
log=Path(sys.argv[1]);code=int(sys.argv[2]);last=None
for line in log.read_text(errors='replace').splitlines():
    try:event=json.loads(line)
    except ValueError:continue
    if event.get('type')=='message_end' and event.get('message',{}).get('role')=='assistant':
        message=event['message']
        last={key:message.get(key) for key in ('provider','model','thinkingLevel','stopReason','errorMessage')}
if code==0 and (last is None or last.get('stopReason')=='error'):code=86
log.with_suffix('.outcome.json').write_text(json.dumps({'process_exit':int(sys.argv[2]),'effective_exit':code,'last_assistant':last},indent=2)+'\n')
print(code)
PYOUTCOME
)

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

"$ROBOENV_ROOT/.venv/bin/roboenv" stop "$RUN_ID" --json > "$KINEX_TASK_ROOT/logs/robodojo-stack-bowls-recovery10-20261022T030720Z-stopped.json" || true
exit "$AGENT_EXIT"
