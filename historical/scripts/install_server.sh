#!/usr/bin/env bash
set -euo pipefail
TASK=${KINEX_TASK_ROOT}
mkdir -p "$TASK"/{home,bin,tmp,logs,downloads,cache,python,workspaces}
export HOME="$TASK/home"
export TMPDIR="$TASK/tmp"
export XDG_CACHE_HOME="$TASK/cache"
export UV_CACHE_DIR="$TASK/cache/uv"
export UV_PYTHON_INSTALL_DIR="$TASK/python"
export UV_NO_CACHE=1
export PATH="$TASK/bin:$HOME/.local/bin:/root/.local/bin:$PATH"
export KINEX_DATA_DIR="$TASK/kinex-data"
export PYTHONNOUSERSITE=1
export HTTPS_PROXY=http://127.0.0.1:19823
export HTTP_PROXY="$HTTPS_PROXY"
export NO_PROXY=localhost,127.0.0.1,::1
export NODE_USE_ENV_PROXY=1
exec > >(tee -a "$TASK/logs/install.log") 2>&1
date -Is
available=$(df --output=avail -B1 "$TASK" | tail -1)
if (( available < 2147483648 )); then echo 'Need at least 2 GiB free before bootstrap'; exit 14; fi
if [[ ! -x "$TASK/bin/uv" ]]; then
  cp /root/gpufree-data/aspire-goal-swap-20261020/bootstrap-tools/bin/uv "$TASK/bin/uv"
fi
uv --version
if [[ ! -x "$TASK/node/bin/node" ]]; then
  curl -fsSL --connect-timeout 15 --max-time 90 https://nodejs.org/dist/latest-v22.x/SHASUMS256.txt -o "$TASK/downloads/node-SHASUMS256.txt"
  filename=$(awk '$2 ~ /^node-v22\.[0-9]+\.[0-9]+-linux-x64\.tar\.xz$/ {print $2}' "$TASK/downloads/node-SHASUMS256.txt")
  test -n "$filename"
  curl -fL --retry 2 --connect-timeout 15 --max-time 180 "https://nodejs.org/dist/latest-v22.x/$filename" -o "$TASK/downloads/$filename"
  (cd "$TASK/downloads"; grep "  $filename\$" node-SHASUMS256.txt | sha256sum -c -)
  mkdir -p "$TASK/node"
  tar -xJf "$TASK/downloads/$filename" --strip-components=1 -C "$TASK/node"
fi
export PATH="$TASK/node/bin:$PATH"
node --version
npm --version
curl -fsSL --connect-timeout 15 --max-time 90 https://raw.githubusercontent.com/stacx-lab/kinex/15207927c6669fe98f1213a3fd05148e0fe938d3/install.sh -o "$TASK/downloads/kinex-install.sh"
bash "$TASK/downloads/kinex-install.sh"
kinex --version
if [[ ! -d "$TASK/RoboEnv/.git" ]]; then
  git init "$TASK/RoboEnv"
  git -C "$TASK/RoboEnv" remote add origin https://github.com/stacx-lab/RoboEnv.git
  git -C "$TASK/RoboEnv" fetch --depth 1 origin c071a25b6866d3843459ebfd4453dc300243cdc6
  git -C "$TASK/RoboEnv" checkout --detach FETCH_HEAD
fi
cd "$TASK/RoboEnv"
bash tools/bootstrap.sh
.venv/bin/roboenv tasks list --simulator libero
echo 'KINEX_AND_ROBOENV_BOOTSTRAP_COMPLETE'
