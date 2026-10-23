#!/usr/bin/env bash
set -euo pipefail

source "${KINEX_TASK_ROOT:?Set KINEX_TASK_ROOT}/env.sh"
export ROBOENV_ENDPOINT=http://127.0.0.1:8123
cd "$KINEX_TASK_ROOT/workspaces/libero-spatial-03"

exec timeout 1500 kinex \
  --auto \
  --provider openai-codex \
  --model gpt-6.1-sol \
  --thinking high \
  --mode json \
  -p 'Operate the currently running LIBERO simulator through Kinex only. The task is: Pick the akita black bowl from the table center and place it in the center of the plate. Begin by checking the available devices and loading/pinging any that are not ready. Inspect camera observations and robot state, then use the Kinex device tools to perform the task carefully. Do not use shell commands or call the RoboEnv driver directly. Verify the final state through Kinex observations; report what happened honestly.'
