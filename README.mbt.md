# ptp-audit 0.3.0

`ptp-audit` 是一个离线 MoonBit PTP 核验库和命令行工具，面向 PTP 网络部署验收与同步异常复盘。它在明确的 IEEE 1588-2008 default multicast E2E two-step 子集内，将报文身份关联、精确 correction 测量、有效 BMCA 快照与选主巡检连接起来：既检查四帧能否组成交换，也检查这组交换是否来自该时段声明选中的直接上游。它不采集网卡数据、不调整系统时钟，也不实现完整 IEEE 一致性或完整 BMCA 端口状态算法。

本版本输入 schema 为 `ptp-audit/v1`，结构化报告为 `ptp-audit-report/v2`。主要能力包括：

- `observation/`：显式 epoch、捕获窗口、时钟域和完整性策略；按明确预算跟踪 pending 交换，只有窗口覆盖到 deadline 且完整性已确认时才报告过期。未完成窗口或可能存在采集丢失时保留为证据不足。
- `exchange/`：核对 Sync/Follow_Up 与 Delay_Req/Delay_Resp 身份和时序上下文，处理乱序、重复、序号回绕及观察窗口边界。
- `bmca/`：在同一有效观察快照中核对 Announce 候选与设备声明的选择。缺少有效期、候选完整性、资格或捕获窗口证据时不将偏好比较表述为已确认设备决策。
- `evidence/`：在报告中给出实际字段、比较值、关联键、测量操作数、输入假设、规则来源和未覆盖范围。
- `metrology/`：从已接受四帧重建原始/修正 offset 与 mean delay，分别列出 Sync、Follow_Up、Delay_Resp correction 的有符号贡献，明确 Delay_Req correction 不再扣除。可使用调用者提供的时间戳、correction 和完整路径差误差上界，给出精确有理数区间与独立的同步门限结论。
- `commissioning/`：将有效 BMCA 的选中 Announce 与完整交换逐帧绑定，要求相同观察上下文、接收端和覆盖四帧的选择稳定/Announce 有效区间。跨相邻检查点分别判断直接上游端口和 grandmaster 是否改变，拒绝旧主交换污染、矛盾稳定区间和跨越失败检查点的推断。

巡检 campaign 使用新增输入 `ptp-commission/v1` 和报告 `ptp-commission-report/v1`；原 `check` 输入仍为 `ptp-audit/v1`，可选增加 `error_budget`，原报告 v2 增加 `metrology`。库入口包含 `audit_json` 和 `commission_json`。详细字段和边界见[部署巡检说明](docs/commissioning.md)。

## 模块与源码入口

- Mooncakes 模块：[`001-Elsa/ptp-audit@0.3.0`](https://mooncakes.io/docs/001-Elsa/ptp-audit@0.3.0/)。
- GitHub：<https://github.com/001-Elsa/ptp-audit-mbt>。
- GitLink：<https://gitlink.org.cn/Hzhhhh/ptp-audit-mbt>。

Mooncakes 包用于库消费和所附自构造测试，省略体积较大的 `research/` 审查证据。完整源码、独立参考生成、全量验证和参赛归档请使用上述 Git 仓库；其中保留全部原始证据。registry 包内的代码、接口、测试、文档及 PDF 与完整源码逐文件保持相同字节。

在 MoonBit 消费项目中添加已发布模块：

```sh
moon add 001-Elsa/ptp-audit@0.3.0
```

在消费包的 `moon.pkg` 中声明入口并使用别名：

```moonbit nocheck
///|
import {
  "001-Elsa/ptp-audit" @ptp,
}
```

`@ptp.audit_json(input)` 和 `@ptp.commission_json(input)` 接收 JSON 字符串并返回报告 JSON 字符串；更细的 typed API 分布在各子包。仓库中的 CLI 可直接运行下面的自构造案例。源码发布、registry 版本可下载和远端 CI 结果分别验证，具体流程见[发布与复现说明](docs/release-runbook.md)。

## 标准库版本要求

本项目使用官方 Core JSON 的 `reject_duplicate_keys` 严格解析参数。已验证组合为 MoonBit `0.10.15+943464bfa` 加官方 [Core 提交 eb321a18](https://github.com/moonbitlang/core/tree/eb321a18f7a33d37114546682a8d1cd6658afab8)。仅安装同编号编译器的历史 bundle，其附带 Core 可能较旧，不能保证提供该参数。CI 在安装编译器后单独检出上述官方 Core、重新 bundle 全后端；复现时请使用这个组合，或提供同等 API 的更新官方工具链。没有修改标准库源码来让本机测试通过。具体可执行步骤见[CI 配置](.github/workflows/test.yml)。

## 运行完整案例

需要 MoonBit CLI（本地验证版本 `moonc v0.10.15+943464bfa`）、Node.js 22+ 和 Python 3.9+。

先安装 [MoonBit 工具链](https://docs.moonbitlang.com/en/latest/tutorial/tour.html)、Node.js 并将二者加入 PATH；独立参考向量和 native 后端另需系统 C 编译器。CI 固定 MoonBit `0.10.15+943464bfa` 与官方 Core `eb321a18f7a33d37114546682a8d1cd6658afab8`、Node.js 24 和 Python 3.12，产品库不依赖 Python 或外部 TShark。

```sh
./bin/ptp-audit.mjs check fixtures/complete-audit.json --json
# 两个有效选主检查点与交换的完整证据链
./bin/ptp-audit.mjs commission fixtures/commissioning/grandmaster-switch.json --json
# 原交换本身有效，但来源仍是旧主：预期 Violation / exit 1
./bin/ptp-audit.mjs commission fixtures/commissioning/old-master-after-switch.json --json
# 条件同步门限：同时查看 assessment.verdict，不能只读退出码
./bin/ptp-audit.mjs check fixtures/commissioning/metrology-within-limit.json --json
```

该 fixture 是人工构造的六帧样本，包含 Sync、Follow_Up、Delay_Req、Delay_Resp 和两个 Announce。它用于展示完整输入/报告流程，不是硬件抓包。其他固定案例和预期状态见 `fixtures/manifest.json`；原 manifest 有 116 个案例条目，新增部署巡检/误差预算 manifest 有 53 个案例。0.3.0 本轮 `check --target all --deny-warn`、CLI 116 个原案例 + 53 个部署案例 + 7 个边界、`moon info`、`moon fmt --check` 均已通过。四后端最终测试数及所有日志见 [验收记录](docs/validation.md)。

## 观察证据和报告边界

PTP 报文时间与采集时钟属于不同数据。关联与测量需要输入明确的 observation window、epoch、clock domain、capture time 及必要的方向/端口信息。对于缺失响应，只有调用者给出有效 deadline policy，并确认捕获窗口连续完整且覆盖 deadline，工具才会把 pending 项标记为 expired；expired 仍不自动证明设备违规。

BMCA 检查需要同一观察上下文中的 Announce、候选完整性和资格声明、决策时刻、Announce 有效期来源及捕获窗口确认。报告的 `Pass` 仅针对报告列出的已执行规则和输入证据，不认证来源真实性、绝对时钟精度、整个网络状态或完整标准符合性。

Correction 保留为有符号 scaled-nanoseconds，单位为 2^-16 ns；测量使用精确整数运算。CLI 输入和项目数据均有资源上限。各规则支持边界见 [规则说明](docs/rules.md)、[逐规则来源与限制](docs/rule-traceability.md)、[规则与规范证据边界](docs/normative-evidence.md) 和 [架构](docs/architecture.md)。

`Pass` 表示输入证据上的计算/核验通过。部署门限另给出 `within_limit`、`outside_limit`、`indeterminate`，无预算时为 `unassessed`；有效计算即使得出 `outside_limit` 也不会伪称协议违规。campaign 的 `operational_acceptance` 汇总这一层结论。来源、界限、稳定性与捕获时钟连续性均由调用者提供，工具不能认证它们。现有 `symmetric_path` 表示接受对称路径作为名义估计模型；新增非零路径差上界只评估这一模型可能偏离的条件误差，不从四个时间戳反推实际不对称。

这些能力可用于检查工业以太网、测量设备或分布式采集系统的 PTP 证据；本项目的演示数据全部为人工构造，不代表这些行业或设备已经实测。可复现的故障场景和预期输出见[演示手册](examples/commissioning.md)。

## 本地验证与来源

```sh
# 一次完成生成稳定性、全部后端、CLI、报告、接口与格式门禁
python3 scripts/validate_local.py
# 如另行安装了官方 TShark，则加入独立 wire 核对
python3 scripts/validate_local.py --with-wire
# 核对文档、接口、数量与当前测试结果，冻结本地交付快照
python3 scripts/verify_delivery.py --write
# 仅生成本地 ZIP，并在临时目录解包验证，绝不发布
python3 scripts/package_local.py
```

上述命令是复现步骤；是否通过以及本轮实际测试数见 [验收记录](docs/validation.md)。独立 wire 检查使用外部 TShark 对六个构造 PTP payload 做双遍解码，并核对 130 个字段；它验证这批样本的解码，不是 IEEE 认证，也不是设备实测。BMCA 参考向量来自 LinuxPTP C 实现；完整来源与适用限制见 [验证说明](docs/validation.md) 和 [wire 交叉验证](docs/wire-reference.md)。

## 规范和交付状态

逐规则官方来源已登记，但完整授权 IEEE 1588-2008 正文尚未取得。公开解释、实现参考和 TShark 样本只支持各自明确的范围，不能把完整规范门禁写成通过；未确认的条款和解释冲突见 [规则依据表](docs/rule-traceability.md)。原计划逐项状态见 [计划核对表](docs/plan-requirements-audit.md)。

当前面向 [2026 MoonBit 黑客松十月赛](https://moonbitlang.github.io/Hackathon2026/) 准备本地提交材料；官网注明报名与验收截止为 2026-10-31。已提供[一页项目申报书正文](PROJECT_APPLICATION.md)、[PDF](output/pdf/ptp-audit-项目申报书.pdf)和[材料说明](docs/submission-ready.md)，明确本期实质新增工作。本次已按用户新指示启动 GitHub、GitLink 分内容分批同步及 Mooncakes 发布；实际远端结果记录在 `research/publication/current.json`，不能由本地测试推断。个人信息与正式报名由官方表单另行提供；完整飞书章程仍因登录限制未取得，旧 6 月副本保留为历史核对依据。当前主体为 6,004 行有效生产 MoonBit，统计不含测试、research、build、空行和整行注释；具体工程和交付状态见 [交付核对](docs/charter-compliance.md)。

许可证为 Apache-2.0。第三方代码和工具来源边界见 [THIRD_PARTY.md](THIRD_PARTY.md)。授权未明确的外部 Wireshark 抓包已退出当前源码/交付树；过关示例与 wire 验证 PCAP 全部自构造，不冒充设备抓包。

当前相似性复查以 2026-10-20 捕获的 3,140 条官方模块索引和逐包完整源码扫描为范围；五类 PTP 报文结构、scaled-ns correction、四帧关联、限定 BMCA 和通用请求响应/窗口/报告功能的已确认交集与证据边界见[复查记录](docs/non-overlap-current.md)。本地检索不能证明绝对零相似或赛事通过；用户要求的严格门槛尚不能判为满足。
