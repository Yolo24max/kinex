# 阅读与新运行

## 离线复盘

打开三个 `tasks/` 目录中的 README。先看 `result.json` 和 `evidence/terminal.json`，
再按 `code/tool-calls.json` 的 sequence 阅读 Python 片段、设备调用和设备驱动。
工具调用来自实际成功回合，不包含模型隐藏推理或逐 token 流。

```bash
python scripts/verify_results.py
```

该命令核对发布文件哈希、三项原生终态、完整工具调用及代码提取，不访问服务器。
它不证明新环境可以成功启动，也不替代 GPU 重跑。

## 准备新的 Linux 环境

需要兼容 NVIDIA GPU、仿真器资源、uv、FFmpeg、KinEx 及模型登录。
使用固定的历史源码而非自动追随 main：

```bash
git clone https://github.com/stacx-lab/RoboEnv.git /path/to/RoboEnv
cd /path/to/RoboEnv
git checkout c071a25b6866d3843459ebfd4453dc300243cdc6
git apply /path/to/this-repo/patches/roboenv/setup.patch
git apply /path/to/this-repo/patches/roboenv/robodojo_assets.patch
bash tools/bootstrap.sh
source .venv/bin/activate
roboenv prepare libero
# 其他两个任务分别准备 robotwin / robodojo；按原环境隔离安装，不把依赖混装。
```

两处服务器补丁仅把资产下载/准备超时从 1800s 增至 21600s，没有修改评分或控制规则。
`vendor/RoboEnv/` 保存未改动的上游快照，供无需联网时阅读；新安装使用上面的独立 Git checkout，
以保留子模块及 provisioning 所需的 Git 元数据。

KinEx 的固定源码在 `vendor/kinex/`，提交和来源见 `provenance/upstreams.json`。
可按其 README 安装 v1.0.0 或从该快照构建。模型登录在本机完成，仓库没有登录凭据。
任务所需资产和安装步骤以固定源码 `docs/setup.md` 及对应后端说明为准。

## 预览与执行

```bash
python scripts/run_task.py libero-spatial-03 --roboenv-root /path/to/RoboEnv
python scripts/run_task.py robotwin-handover-block --roboenv-root /path/to/RoboEnv
python scripts/run_task.py robodojo-stack-bowls --roboenv-root /path/to/RoboEnv
```

以上默认仅输出计划。添加 `--execute` 才会启动仿真并调用模型。
新证据写入 `.runs/`，不会覆盖归档的成功结果；端口被占用时拒绝执行，不停止已有服务。
设备导出后还需满足其 `.kinex/python/` 依赖；首次工具运行按 KinEx 的隔离 Python 规则初始化，
若缺少特定包，可参考任务工作区的 pyproject.toml、uv.lock 和 historical/scripts 中当时的修复命令。

历史三项都使用 seed=0。便携入口遵循固定后端默认种子；要做严格多种子评测，
应另行明确 seed、协议、预算和冻结版本，保存新的运行配置与原生 verdict。

`code/step_*.py` 不是独立的 solve.py。它们依赖当时图像反馈、变量和设备状态，
不能通过直接串联脚本保证重放。新模型运行也不保证再次成功。
