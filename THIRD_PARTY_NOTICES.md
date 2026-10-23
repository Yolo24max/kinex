# 来源和第三方代码

本仓库整理三个已完成的 KinEx 功能复现，不代表上游维护者。

- `vendor/kinex/`：stacx-lab/kinex，v1.0.0，提交 `15207927c6669fe98f1213a3fd05148e0fe938d3`，原始 Apache-2.0 LICENSE 和 THIRD_PARTY_NOTICES.txt 原样保留。
- `vendor/RoboEnv/`：stacx-lab/RoboEnv，提交 `c071a25b6866d3843459ebfd4453dc300243cdc6`，上游源码快照，未套用本仓库或 KinEx 的许可证；以原文件声明及上游权利说明为准。
- `patches/roboenv/`：服务器实际使用过的两处 provisioning 修改，原始文件和服务器版本哈希见 provenance/upstreams.json。
- `tasks/*/workspace/`：由 RoboEnv 导出的设备工作区；不是独立设计的设备框架。
- `benchmarks/`：官方公开基准任务描述；保留原始任务身份及数据来源。

仿真器、模型权重、商业资产和第三方子模块没有被重新打包到这里，需按各上游条款获取。
