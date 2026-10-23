# 证据与完整性

每个任务的 `evidence/terminal.json` 保留原始字节，并由 `result.json` 记录 SHA-256。
`code/tool-calls.json` 来自成功回合的 assistant message_end/toolCall，记录原始工具参数。
未发布模型隐藏推理、逐 token 流、图片 base64、认证状态或服务器连接信息。

完整 agent 日志、动作记录、多视角视频和观察仍保留在已有本地备份。
`evidence/original-artifacts.json` 列出原始文件的大小与哈希，供持有备份的人核对。
这些清单不是公开下载地址，GitHub 仓库不包含视频/完整大日志。

RoboDojo 的 native evidence.complete=true，但 diagnostics_complete=false；不能用部分诊断独立重算所有终态指标。
本次整理没有重跑任何仿真、模型或正式评测。
