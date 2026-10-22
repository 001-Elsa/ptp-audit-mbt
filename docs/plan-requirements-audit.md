# 大改计划逐项核对

当前本地参赛材料状态已于 2026-10-22 更新，见 [提交材料说明](submission-ready.md)。本页保留大改技术计划的逐项核验，6 月章程相关文字视为历史依据；本期以新 Hackathon 官网可读十月要求补充校核。

本文把 [redesign-plan.md](redesign-plan.md) 的原始目标与 0.3.0 当前实现分开记录。状态只表示代码能力或已有证据，不把实现完成、测试通过、规范依据和外部交付混为一项。用户现已授权 GitHub/GitLink 按内容分批同步与 Mooncakes 发布，各平台结果独立记录在 `research/publication/current.json`；正式报名仍由本人办理；门禁结果见 [validation.md](validation.md)。

## 状态定义与核对依据

- **已实现**：代码中有相应机制；不自动代表验证通过。
- **本地已验证**：本轮有可复核的本地命令和结果。
- **规范待核**：缺少可合法使用的完整 IEEE 1588-2008 正文，官方公开解释或实现参考只能支撑有限条目。
- **外部单独核验**：GitHub/GitLink/Mooncakes 与远端 CI 根据实际远端证据判断；正式报名由本人办理，旧章程条目不能代替本期全文。

本次文档更新依据当前源文件、`docs/rule-traceability.md`、`docs/wire-reference.md`、`research/wire-reference/verification.json`、fixture manifest 和本轮 `research/validation-0.3.0/` 日志。本轮 check、四后端测试（每后端 455/455）、CLI 116 个原案例 + 53 个部署案例 + 7 边界、info 和 fmt-check 均已通过。旧 `research/validation/` 中的 0.2.0/289 项记录不代表当前版本。本轮测得 6,004 有效 MoonBit 行，不含 tests/research/build、空行和整行注释。

## 第 1–4 节：范围、方向、迁移与支持边界

| 计划要求 | 当前状态 | 证据与限制 |
|---|---|---|
| 不宣称绝对零相似；披露基础能力交集 | 已落实为文档边界 | `docs/non-overlap-current.md`、历史报告与 README 保留查重覆盖和基础能力限制。查重不是比赛原创性裁定。 |
| 面向指定 PTP 子集做离线报文、观察、BMCA 核验 | 已实现 | 0.3.0 使用 `wire/`、`exchange/`、`observation/`、`bmca/`、`audit/`、`evidence/`、`diagnostic/` 与 CLI；不调系统时钟。 |
| 移除通用仿真、伺服/调钟和紧凑自定义协议 | 已落实 | 正式产品模块不再提供旧模拟器入口；历史原型保存在 research 归档。 |
| IEEE 1588-2008 default multicast E2E two-step 五种固定消息 | 已实现；规范门禁部分待核 | 独立 TShark 4.6.9 对实际六帧五类消息做 130 项字段核对，见 `docs/wire-reference.md`。这验证样本解码，不是完整标准认证。 |
| 明确范围外 profile/TLV/模式，不静默判 Pass | 本地已验证 | 当前实现对未支持输入返回明确状态；116 个 CLI 案例及 7 个边界检查全部符合预期。 |
| 完整 IEEE 规范及赛事原创性尺度已核实 | 未完成 | 逐规则来源和未确认条款见 `docs/rule-traceability.md`；完整授权正文未取得。不得宣称完整规范门禁通过。 |

## 第 5–6 节：三项协议核心与用户闭环

| 计划要求 | 当前状态 | 证据与限制 |
|---|---|---|
| signed scaled-ns correction、亚纳秒精确运算及边界处理 | 本地已验证，规范解释部分待核 | `wire/` 保留有符号字段，测量用精确整数；独立 TShark 样本和 wire 极值向量分别覆盖有限部分。tooBig sentinel 的官方解释存在冲突，规则表保留该限制。 |
| 依据身份、domain、epoch、窗口和时限关联 two-step/E2E 观察 | 已实现 | `observation/observation.mbt` 提供窗口/策略/样本验证；`exchange/context.mbt` 实现 pending、按 deadline 配对、过期/保留状态。没有完整观察证据时不把缺包升级为设备违规。 |
| BMCA 只对有证据的有效快照比较 | 已实现 | `bmca/snapshot.mbt` 要求明确 epoch、window、clock domain、decision time、Announce 有效期及来源、资格和捕获窗口确认，并检查候选观察上下文。BMCA 仍不是完整 foreign-master qualification 或端口状态算法。 |
| 可解释报告包含实际字段和证据 | 已实现为 report/v2 | `evidence/` 输出输入/帧字段、关联比较、计算操作数、观察上下文、BMCA 快照、规则来源和覆盖范围。仅对实际执行规则给出 Pass；不证明外部声明本身真实。 |
| 固定、可追溯的正反例和 CLI 行为 | 本地已验证 | `fixtures/manifest.json` 的 116 个案例以及 7 个 CLI I/O 边界检查均通过；manifest 记录状态、规则、哈希和来源。构造 fixture 不冒充硬件抓包。 |

## 第 7 节：阶段门禁

| 阶段 | 当前状态 | 说明 |
|---|---|---|
| 0 范围和相似性 | 部分完成 | 2026-10-20 11:34:58 捕获官方索引 3,140 条；逐包扫描该索引所有当前版本，3,140/3,140 为 ok，284,094 文本文件、290,395 个成员哈希已核对；完整范围与功能交集见 [当前相似性复查](non-overlap-current.md)。通用能力交集已披露；完整授权规范正文和官方原创性裁定仍缺。 |
| 1 标准 wire | 实现完成，规范门禁部分待核 | 五类消息实现；TShark 对六帧 130 项核验通过。有限样本不能替代完整规范正文、所有边界或认证。 |
| 2 观察关联 | 已实现并本地验证 | 新增 observation 包、显式窗口/epoch/policy、deadline 生命周期；116 个 CLI fixture 和 7 个 CLI 边界通过。 |
| 3 BMCA | 已实现并本地验证 | 新增有效 Announce snapshot 和上下文验证；1,012 项 report evidence 检查通过；不扩展为完整 BMCA 端口状态机。 |
| 4 本地交付 | check、测试、CLI、info/fmt 已通过 | 四后端各 455/455；fixture 再生成 `stable=true`, `changed=[]`，见 `research/validation-0.3.0/`。 |
| 5 外部交付 | 按新指示执行、逐站验收 | 向指定 GitHub/GitLink 分内容提交并分批推送，发布 `001-Elsa/ptp-audit@0.3.0`；ref、registry 和 CI 实证独立记录，正式报名由本人办理。 |

## 第 8 节：原创性和适用边界

项目仍共享时间、字节解析、状态关联、规则诊断等通用基础能力。现有检索不证明绝对零相似，也不能预测官方原创性裁定。若出现同 profile 的 two-step 关联或 BMCA 决策核验实现，应重新评估；不能以改名、换术语或增加报告掩盖重合。

本地 2026-06-17 章程副本写有 4–10k LOC 参考范围、GitHub 10–20 有效提交、GitLink 同步和 Mooncakes 发布等要求。2026-10-22 新官网已明确十月赛期、最多 3 人组队、一页说明与本期实质贡献；完整飞书正文仍不可读，不将旧条款冒充已核实本期条款。当前统计为 6,004 有效生产 MoonBit 行，排除 tests/research/build、空行和整行注释；不以填充代码或虚构提交追数字。平台交付已按用户新指示纳入执行，当前一页 PDF、源码及文档/验证材料已纳入交付流程，具体远端完成状态不能由本地结果推断。

完成状态的表达规则：功能已实现不等于本地验证通过；本地验证通过不等于 IEEE 完整合规；本地打包或工作流文件存在不等于远端 CI、公开仓库、正式提交或回执完成。每项只有在对应证据已保存后才可改成完成。

## 第 9 节：部署巡检增强

本轮新增 `metrology/` correction 贡献账本与条件误差预算，以及 `commissioning/` 有效选主到四帧的逐帧绑定和相邻选择变化判断。已实现 53 个独立构造/校验案例；代码与复现命令见 [部署巡检说明](commissioning.md)、[演示手册](../examples/commissioning.md) 和 `research/commissioning/manifest.json`。原四层验收继续执行，新规则纳入同一份实现清单；这些是项目证据政策和代数解释，不扩大 IEEE 标准支持子集。
