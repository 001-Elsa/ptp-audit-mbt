# 当前赛事与本地交付核对

更新：2026-10-22；当前版本：0.3.0。当前交付入口见 [提交材料说明](submission-ready.md)，逐条旧章程核对保留在 [2026-10-21 历史报告](charter-audit-2026-10-21.md)。本页按已取得的新 Hackathon 官网要求与当前代码、材料更新，不用旧状态覆盖当前结果。

## 当前适用来源

[2026 MoonBit 黑客松官网](https://moonbitlang.github.io/Hackathon2026/) 本期为十月赛，报名与验收截止 2026-10-31，每队不超过 3 人；十月最多提交 3 次，按审核通过前最后一次有效提交/修改计时。官网要求 MoonBit 主体、清晰 README、可运行示例、必要测试、开源许可证/来源说明，以及已有项目的本期实质贡献；申报附一页项目说明。公开原文和哈希见 `research/contest-2026-10-22/website-source.json`。

官网链接的飞书正文仍跳转登录，完整当前章程未取得。2026-06-17 本地副本中个人参赛、7 月赛程和推荐细则等与当前官网有差异，只保留作历史核对，不擅自声称全文已核实。用户已授权 GitHub/GitLink 按内容分批同步及 Mooncakes 发布；具体远端凭据、分批提交、registry 下载和 CI 验证结果保存在 `research/publication/current.json`。个人信息仍按用户要求不写入 PDF。

## 工程与材料逐项状态

| 要求或原缺口 | 当前状态 | 实际证据 |
|---|---|---|
| MoonBit 主要实现语言 | 已满足本地范围 | 18 个生产 MoonBit 文件，wire、exchange、observation、bmca、metrology、commissioning、audit 与 evidence 等负责全部核心判断；JS 仅适配输入/运行。 |
| 明确功能、真实需求、可复用接口 | 已具备 | 面向 PTP 部署验收/异常复盘；`audit_json`、`commission_json` 及 check/commission；README 写明子集与调用者假设。 |
| 代码规模参考 | 6,004 行有效生产 MoonBit | 排除 tests/research/build、空行和整行注释；新官网重点是工程质量，旧官网 4–10k 为参考。 |
| 正确处理关联、观察窗口与 BMCA 证据 | 当前实现已验证 | 明确 epoch、window、clock、deadline 与有效 Announce snapshot；缺证据不冒充设备违规。 |
| 本期实质新增贡献 | 已说明、可追溯 | correction 贡献账本、条件预算、所选上游与四帧绑定、全 campaign 稳定性冲突检查，53 新案例；申报书与 CHANGELOG 区分已有基线。 |
| 源码结构清晰且功能可运行 | 本地已验证 | 全目标 check、四后端各 455/455；169 CLI 案例及 7 边界，1,012 报告检查、935 独立巡检检查。 |
| README 与可复现示例 | 已具备 | 依赖与运行命令、正反例、解释指南；文档同步校核检查 API/schema/数量/链接与源码哈希。 |
| CI 完整性 | 配置已修正、本机命令已复现 | 统一 validator，补全独立 commissioning/规则门禁；显式 build，文档检查，干净解包验收；没有远端执行声明。 |
| 独立 wire 样本 | 有限定实证 | 外部 TShark 解码六帧、五消息、130 字段；样本由项目生成，见 wire-reference 与本轮 wire 日志；不是设备抓包或标准认证。 |
| 一页项目申报书 | 已制作 | `PROJECT_APPLICATION.md` 与 `output/pdf/ptp-audit-项目申报书.pdf`；单页 A4、字体嵌入、正文哈希和 PDF 字节校核，身份信息按用户指示省略。 |
| OSI 开源许可证与参考来源 | 主体已落实 | Apache-2.0；THIRD_PARTY 列 Core、LinuxPTP GPL 参考、独立工具和标准材料边界。 |
| 外部抓包再分发证据缺口 | 通过退出当前交付处理 | `research/wireshark/ptpv2.pcap` 移出工作树，保留来源/哈希；ignore 与归档拒绝测试防回流，旧 Git 历史不进入交付。 |
| 源码及材料归档 | 已纳入交付门禁 | package_local 验证当前文件/证据并解包运行；package_submission 核对源码 ZIP、PDF 与所有清单。源码包含当前增强，不只取旧 HEAD。 |
| 开发生命周期与提交历史 | 按实质变更冻结 | 保存代码、测试、文档和证据；不制造空提交补旧版次数，也不把 Git 本地提交等同远端发布。 |
| 原创性/高重合项目检查 | 有固定范围证据，保留裁定边界 | 2026-10-20 3,140 条当前版本快照绑定当前 18 文件；通用交集披露，未确认完整同类 PTP 组合复制。不能证明绝对零类似或替代赛事评审。 |
| 完整 IEEE 标准认证 | 未声明，不是本轮通用赛事门槛 | 完整授权正文未取得；公开解释、LinuxPTP、教程、TShark 仅提供各自范围旁证。 |
| GitHub/GitLink/Mooncakes 与远端 CI | 本次执行并单独核验 | 分内容提交并分批推送指定仓库；包名 `001-Elsa/ptp-audit@0.3.0`；完成状态、远端 ref 与 registry 校验见 `research/publication/current.json`。 |
| 本人身份、队伍/群昵称、报名次数、审核回执及入围答辩 | 官方流程待本人确认 | 本地材料不代替身份提交、法律同意、正式受理或资格裁定。旧个人参赛条款不能直接取代本期最多三人规则。 |

## 当前交付结论

本地工程与提交附件按可复现交付准备；原有可落实缺口已通过材料制作、样本退出交付、CI 对齐和文档/源码绑定处理。验收数字及源码哈希以 `research/validation-0.3.0/manifest.json`、`research/delivery/current.json` 及最终归档清单为准，文档不能替代未通过的日志。

本地材料完成不等于完整在线章程已取得、官方已受理或所有外部流程完成。声明功能保持受限离线 PTP 核验，不扩张到硬件采集、绝对精度或完整 BMCA/IEEE 一致性。
