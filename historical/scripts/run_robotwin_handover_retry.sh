#!/usr/bin/env bash
set -euo pipefail

source "${KINEX_TASK_ROOT:?Set KINEX_TASK_ROOT}/env.sh"
export ROBOENV_ENDPOINT=http://127.0.0.1:8124

TASK_ROOT="$KINEX_TASK_ROOT"
WORKSPACE="$TASK_ROOT/workspaces/robotwin-handover-block"
AGENT_LOG="$TASK_ROOT/logs/robotwin-handover-kinex-retry.jsonl"
RUN_ID=88344d1ba02872af

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

"$TASK_ROOT/RoboEnv/.venv/bin/roboenv" stop "$RUN_ID" --json > "$TASK_ROOT/logs/robotwin-handover-stopped.json" || true
printf 'EXIT=%s\n' "$AGENT_EXIT" >> "$AGENT_LOG"
exit "$AGENT_EXIT"
