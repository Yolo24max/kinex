# KinEx 官方项目复现记录

## 本次完成的官方任务

- KinEx：v1.0.0
- 仿真环境：RoboEnv / LIBERO
- 任务：`libero/libero-spatial-03`
- 随机种子：`0`
- 运行模式：`practice`、`realtime`
- 指令：将桌面中央的黑色秋田犬碗放到盘子中央。
- 智能体：KinEx，`openai-codex` 提供方，`gpt-6.1-sol`，high reasoning

## 原生判定

RoboEnv 在累计执行 `9339` 个 action frames 后进入终态。本回合 `budget.max=null`，未设置官方动作步数上限。原生 verdict 为：

| 字段 | 值 |
| --- | --- |
| `success` | `true` |
| `reason` | `success` |
| `raw_score` | `1.0` |
| `reward` | `1.0` |
| `submitted` | `true` |
| `evidence.complete` | `true` |

这一次为实际 KinEx 智能体通过设备 API 操作 RoboEnv 的回合；成功标志由仿真器原生任务判定产生。

## 可复核产物

- `evidence/libero-spatial-03/terminal.json`：终态与 verdict，内含 final observation 的 SHA-256。
- `evidence/libero-spatial-03/stopped.json`：停止后的服务状态。
- `evidence/libero-spatial-03/final-observation.json`：最终观测、动作摘要与任务状态。
- `evidence/libero-spatial-03/third_person.mp4`：第三人称录屏，4,668 帧，10 FPS。
- `evidence/libero-spatial-03/wrist.mp4`：腕部视角录屏，4,668 帧，10 FPS。
- `evidence/libero-spatial-03/recording-manifest.json`：录制完整性清单；接收、接受和编码帧数均为 4,668，丢帧为 0。

远端可继续使用的运行目录为 `${KINEX_TASK_ROOT}`；任务回合已正常关闭，因此不会继续占用仿真 GPU。

## RoboTwin 官方任务进展

- 仿真环境：RoboEnv / RoboTwin，任务：`robotwin/handover-block-aloha-agilex`，随机种子 `0`。
- RoboEnv 原生终态：`success=true`、`reason=success`、`terminal=true`；任务 verdict `completed=true`、`submitted=true`、`raw_score=1.0`，使用 6,481 action frames。
- 该回合配置为 `practice` 控制协议，原生 verdict 明确标记 `official_action_equivalence=false`。因此记录为 RoboEnv 原生成功，不宣称达到官方动作等价标准。
- 录制完整：第三人称及左右腕部视角各 2,594 帧，10 FPS，0 丢帧。
- 证据：`evidence/robotwin-handover-block-retry3/native-terminal.json`、`native-episode.json`、`actions.jsonl`、`stopped.json`、`manifest.json` 及三路 MP4。远端原始运行目录仍保留完整。


## RoboDojo：2026-10-22 启动验证与认证恢复

- 官方资产 revision 为 0a709fe7863f6c869a8d141676585a883fce4270；15,365 个文件、41,269,513,111 字节已全部校验，服务器恢复后再次核对数量和大小无缺失。
- recovery9 的 Isaac Sim 渲染器与三路录屏实际启动成功，任务 run_id 为 d4e7a1c5097ed23e。
- 该回合 agent 的第一次请求因已失效 OAuth 被拒绝，没有执行设备操作。原生 terminal：success=false、reason=stopped、completed=false、raw_score=0.0、38 action frames；native-episode 中 commands=[]。这不是任务成功，也不能据此评估模型的操作能力。
- 三路视频每路16帧，录制清单显示0丢帧。17份证据已归档到 evidence/robodojo-stack-bowls-recovery9，逐项通过大小和 SHA-256 校验；原始远端记录保留。
- 历史运行曾在本地恢复模型登录（凭据未收入仓库），并恢复安装版本要求的 config/agent/auth.json → kinex-data/agent/auth.json 链接。未配置付费 API key，未输出凭据。
- 实际不占用GPU的推理验证通过：openai-codex、gpt-6.1-sol、high，返回 KINEX_AUTH_OK；凭据有效性以此请求成功为依据，不以HTTP401/405或CLI退出码代替。
- 已创建独立 recovery10 重试，继续保留 recovery9 的失败证据。入口 run_robodojo_recovery10.sh，使用共享GPU锁与原3GiB启动容量门槛；用户随后明确要求直接启动；已核实资源并取消本任务排队，入口改为 run_robodojo_recovery10_direct.sh，PID37469/start_ticks117047486，进入仿真器启动阶段；该回合现已取得下文记录的原生成功判定。
- recovery10 会单独检查 agent 最终错误，避免将CLI进程返回0误当作推理或实验成功。


## RoboDojo：recovery10 原生成功

- 任务：robodojo/stack-bowls；seed=0；run_id=69874215188f41ce。
- KinEx agent：当前用户 ChatGPT OAuth，openai-codex / gpt-6.1-sol / high；有实际设备操作记录，不是空回合或固定脚本回放。
- RoboEnv 原生判定：success=true、reason=success、completed=true、latched=true、raw_score=100.0、reward=1.0、submitted=true。
- 使用13,295 action frames；运行模式practice/realtime，control_protocol=native_eval_joint_action，official_action_equivalence=false。记录为原生功能成功，不宣称严格官方协议等价复现。
- 原生 terminal 引用的 native-episode.json 与 native-diagnostics.json 均通过SHA-256校验。evidence.complete=true，但diagnostics_complete=false原样保留，部分终态诊断不支持独立重算，不伪造诊断完整性。
- 第三人称、左腕、右腕视频均经ffprobe实际逐帧核验：每路5,319帧、10FPS、960×720；录制清单0丢帧，完整关闭。
- agent最终自述认为右臂未精确回到起始关节位姿，最大关节误差约0.29rad。这项自述与原生成功判定一并保留。原生all_robot_back_to_origin实际阈值为位置0.15m、姿态20°，右臂终态各轴位置误差约0.01094/0.00294/0.04262m、姿态19.36018°，原生检查passed=true；未把“容差内回位”扩写为“精确关节回零”。
- pipeline正常退出；agent最终stopReason=stop、errorMessage=null；仿真器及agent进程均已退出，不再重跑这个成功回合。
- 证据归档：evidence/robodojo-stack-bowls-recovery10；原始远端文件保留。完整归档大小211,449,761字节，SHA-256为fb9f0a2a9e890412e822823edf5aa516818b97175118496feadbd06754aee26e。

## 已覆盖范围

| 环境 | 本次成功任务 | 原生结果 |
| --- | --- | --- |
| LIBERO | libero/libero-spatial-03 | success=true，reward=1.0 |
| RoboTwin | robotwin/handover-block-aloha-agilex | success=true，raw_score=1.0 |
| RoboDojo | robodojo/stack-bowls | success=true，raw_score=100.0，reward=1.0 |

当前是三类环境各1项功能回合成功，共3项；原生raw_score的不同量表不作跨环境直接比较。官方132项任务和三个接口变体的全量评测尚未复现，且模型、控制协议等与已发布基准并非完全一致。


## 与官方发布基准的配置对齐情况

当前三项均为官方任务上的功能复现，不能表述为严格按官方benchmark配置复现。

| 项目 | 官方发布基准 | 本次实际 |
| --- | --- | --- |
| 模型 | GPT-6 Astra / high | 用户指定的gpt-6.1-sol / high |
| 控制协议和预算 | 发布时原生控制协议与固定任务步数预算 | practice/realtime；三项budget.max均为null；LIBERO native_osc_equivalence=false，RoboTwin/RoboDojo official_action_equivalence=false |
| RoboEnv版本 | 应匹配发布基准历史环境 | 固定公开main提交c071a25b6866d3843459ebfd4453dc300243cdc6；历史基准版本尚未完全匹配 |
| 评测覆盖 | 132项任务、三种agent/interface，共396回合 | 3项任务，各一个KinEx功能成功回合 |

选中的三个任务及seed=0与对应官方KinEx案例一致，使用官方来源资产和原生任务判定。官方RoboDojo预算为1875 control steps；本次13295 action frames属于不同协议记录，不能直接按数值比较或声称预算等价。即使按用户要求保留Sol模型，控制协议、预算和历史环境版本仍需另行对齐，才可称“除模型外官方配置一致”。
