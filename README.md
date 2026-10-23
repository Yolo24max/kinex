# KinEx 已完成任务复现归档

这里整理截至 **2026-10-22** 已验证的三个功能成功任务，2026-10-23 归档。
目的：关机后仍可按代码、设备调用和原始终态复盘。不是官方项目发布，也没有完成官方全量 benchmark。

| 环境 | 已完成任务 | 原生结果 | 代码与复盘 |
|---|---|---|---|
| LIBERO | 黑碗放到盘子中央，seed=0 | success=true，reward=1.0 | [libero-spatial-03](tasks/libero-spatial-03/) |
| RoboTwin | 左臂交接木块到右臂，再放蓝垫，seed=0 | success=true，reward=1.0 | [robotwin-handover-block](tasks/robotwin-handover-block/) |
| RoboDojo | 三个碗套叠并返回起始位姿，seed=0 | success=true，reward=1.0 | [robodojo-stack-bowls](tasks/robodojo-stack-bowls/) |

三项使用 `openai-codex / gpt-6.1-sol / high`，practice/realtime，没有设置官方固定动作预算。
LIBERO 的 native_osc_equivalence=false；RoboTwin/RoboDojo 的 official_action_equivalence=false。
因此结果口径是 **三个任务的单回合原生功能成功**，不声称严格官方控制协议、预算或成功率复现。
RoboDojo 的 diagnostics_complete=false 缺口原样保留。raw_score 不同量表不跨环境直接比较。

## 从哪里开始

- [结果总表](results/completed.json)：配置、原生结果、代码片段数量和源日志哈希。
- 各任务 `code/`：从成功回合实际工具调用提取的 Python 代码和全部工具参数。
- 各任务 `workspace/.kinex/`：设备驱动、接口配置和依赖锁。
- 各任务 `evidence/`：原始 terminal、小型结果文件及完整本地证据的哈希清单。
- [运行说明](docs/RUNNING.md)、[详细结果](docs/RESULTS.zh-CN.md)、[证据说明](docs/EVIDENCE.md)。
- [历史启动和恢复代码](historical/)：保留成功前的失败/重试背景。
- [固定上游代码](vendor/)和[服务器 provisioning 修改](patches/roboenv/)；[来源与版本](provenance/upstreams.json)。
- [官方132项任务中文清单](benchmarks/132-tasks.zh-CN.txt)：LIBERO40、RoboTwin50、RoboDojo42；本仓库只完成其中3项的功能回合。

## 本地检查

```bash
python scripts/verify_results.py
python scripts/run_task.py libero-spatial-03 --roboenv-root /path/to/RoboEnv
```

第二条默认仅输出计划。真实新运行需要环境、资产和模型登录准备好后添加 `--execute`。
历史代码片段依赖当时的反馈与状态，不是可以无观察地拼接运行的 `solve.py`。
仓库保留代码和小型证据；多视角视频、完整大日志和运行环境继续保留在原有本地备份。

来源与第三方声明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
