# 最终提交前 Mooncakes 复查（2026-10-19）

本轮在完成实现后重新从官方模块索引取得数据，并对根文档和选定发布源码 ZIP 重新检索。该记录是技术相似性审查证据，不是赛事原创性裁定或提交通过证明。

## 覆盖和结果

- 官方模块索引：3,114 个版本条目；本轮有 10 个版本相对上午审查发生变化，已纳入新的筛查。
- 根文档：3,106 个成功读取，8 个站点明确不可用，0 个网络失败（重试后为 0）。
- 自动命中逐条保留在 `screening-review.json`；PTP、1588、BMCA、grandmaster、gPTP、802.1AS、follow-up 等命中均做了语义处置。
- 发布源码 ZIP：37 个，成功 37 个，失败 0 个；读取 5,019 个文本文件，大小跳过 0 个。第三方源码只读，不执行。

## 与本项目最接近的已知方向

- `xuting22/ntp`：NTP 报文、过滤和偏移/延迟测量；本项目不做 NTP 或通用调钟。
- `mokomoking2501/MoonECAT`、`lockwire`、`moonnet-lab`、`moonlab`、`moonsim`：工业时钟、虚拟时钟或网络仿真；旧模拟器已从正式入口移除。
- `mokomoking2501/profinet_master`：命中 IEEE 802.1AS 可选 MIB 能力字段和普通 follow-up 文本；未发现 gPTP/PTP two-step/BMCA 实现。
- `CJR-ai-nb/evowitness`、`HhWw96/moontxnwitness`、`length-super/moonctl`、`vicTop-cw/mcpconftest`：通用 witness、模型/协议检查或报告抽象；不提供本项目的 PTP 字段关联和数据集比较规则。

本轮没有在审查证据中确认与本项目相同的“PTP two-step 关联 + 限定 BMCA 数据集决策核验”核心实现。该结论不排除未发布源码、历史版本、二进制实现或基础能力交集；因此仍不能写成绝对零类似，也不能替代赛事官方原创性判断。

## 证据

- [官方索引](modules.json)
- [根文档审查](page-audit.json)
- [逐条命中处置](screening-review.json)
- [发布源码审查](source-audit.json)
- [源码命中处置](source-hit-review.json)
- [审查摘要](manifest.json)
