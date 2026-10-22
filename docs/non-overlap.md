# 历史：旧模拟器 Mooncakes 功能重合报告

> 本页是旧模拟器方向的历史核查，不能作为当前 PTP 领域扩展的结论。当前固定 3,140 模块／版本的源码范围、已确认交集与新增领域能力见 [non-overlap-current.md](non-overlap-current.md)。


> 此报告审查对象是已归档的 0.1.0 模拟器，保留原结论作为演进证据。当前 0.3.0 的最新查重见 [当前相似性复查](non-overlap-current.md)；0.2.0 的历史实现后检查见 [旧版复查](../research/2026-10-19-final/review.md)，当前接口以 README/生成 `.mbti` 为准。

检查日期：2026-10-19（Asia/Shanghai）。对象：本工作区 `moonbit-ptp`；本地源码哈希见 [manifest.json](../research/2026-10-19/manifest.json)。

## 结论与此前结论的修正

**存在部分功能相似和重合。按用户要求的“任何类似、重合都不可接受”门槛，当前项目不能标记为可安全提交。** 此前根据 3,041 个模块和少量关键词给出的非重合结论撤回。

本次没有找到公开根文档能够证实的同功能完整 IEEE 1588 PTP/BMCA 实现。扩展标准关键词唯一命中 PROFINET 的 `snmp_feature_ieee_8021as_mib_optional`，只说明有可选 MIB 相关接口，不能据此认定实现了 gPTP。未找到直接 PTP 实现，不等于不存在部分功能相似，也不等于全站全部源码已被证明无重合。

已经证实的交集包括物理时间同步测量目标、工业分布式时钟的漂移/传播延迟处理、网络延迟/抖动/丢包仿真、确定性实验、时间表示和运算。协议不同、项目名称不同、应用领域不同，均不足以排除这些交集。

功能相似不是源码复制证据；本次未开展全生态源码克隆检测。是否违反赛事的正式原创性规则，应按完整官方章程和评审口径认定，本报告不虚构“官方已判失败”或“已通过”。

## 全量范围与可追溯性

| 检查项 | 本次结果 |
|---|---|
| 官方完整模块索引 | 3,113 条，包含 3,032 个未撤回模块与 81 个 yanked 模块；未主动过滤撤回包 |
| 简介为空的模块 | 378 个，也逐包尝试读取文档 |
| 公开根文档有效读取并筛查 | 3,107 个 |
| HTTP/网络等读取失败 | 0 个 |
| 页面返回但文档资源不可用 | 6 个；不得视为无风险 |
| 根文档自动命中复核 | 46 个模块，全部附判定说明；自动命中不等于功能重复 |
| 人工重点对照 | 25 个相近/相关模块，见下表和逐项摘录 |
| 补充深入读取 | 13 个页面/设计文档：网络仿真设计/API、分布式仿真 API/架构、工业虚拟时钟子包等 |

索引入口：[官方模块列表 API](https://mooncakes.io/api-new/v0/modules)。使用索引记录的版本读取 `https://mooncakes.io/docs/<owner>/<module>@<version>`；首次重点读取的未固定版本页面均对应同一索引版本。文档提取正文时排除 script/style，并为正文生成 SHA-256。完整索引、逐包结果和正文快照均已保留。

本次对全部索引条目进行名称、简介、关键词和公开根文档的自动筛查，对 46 个根文档自动命中模块逐项复核，并整理 25 个重点相近项目的语义对照。**不是逐行人工审阅 3,113 个项目全部源码**。未穷举全部嵌套包、仓库分支、历史版本、尚未发布的项目，也不覆盖检查结束后的新增包。未命中只表示在当前可读内容和查询规则下未检出，不表示该模块已获“无任何相似”证明。

直接方向检索包含 PTP、1588、BMCA、grandmaster、802.1AS/gPTP，以及下划线/无点号等写法。邻近方向扩展到 NTP/SNTP、时钟/时间同步、servo、分布式时钟、逻辑/因果时钟、网络/分布式/离散事件仿真、选主、时间表示和控制。完整正则见 [扫描脚本](../scripts/audit_mooncakes.py)；扩展元数据候选见 [expanded-candidates.json](../research/2026-10-19/expanded-candidates.json)。

## 重点模块逐项对照

下列风险标签用于本项目选题审查，不是赛事官方等级。“邻近”不代表已确认同功能重复，但在用户零相似门槛下也不能忽略。

| Mooncakes 项目及版本 | 已核实的现有能力 | 本地对应部分 | 判定和区别 |
|---|---|---|---|
| [xuting22/ntp@0.4.0](https://mooncakes.io/docs/xuting22/ntp@0.4.0) | ClockFilter、Consensus、measure、Timestamp；提供偏移/延迟估计、过滤和时间源组合。 | `Timestamp、ClockQuality/select_grandmaster、Clock::apply_sync、simulate` | **较高：物理时间同步功能部分相似**。NTP 与 PTP 的报文、源选择算法不同；当前 simulate 不是 NTP 的四时间戳测量实现。不能据协议不同排除功能相似。 |
| [Ljh684/moonnet-lab@0.1.0](https://mooncakes.io/docs/Ljh684/moonnet-lab@0.1.0) | 确定性分组网络仿真、虚拟时间、链路延迟、抖动、丢包及实验输出。 | `NetworkModel、SimulationConfig、SimulationReport、simulate` | **较高：网络仿真能力部分重合**。对方主要模拟 TCP 和队列，本地只有简化同步循环；共同的网络仿真功能仍然存在。 |
| [oyjh0381/moonlab@0.1.0](https://mooncakes.io/docs/oyjh0381/moonlab@0.1.0) | 分布式系统仿真、故障注入、确定性调度、重放和轨迹。 | `simulate、SimulationReport` | **中：确定性仿真和故障测试相似**。对方是通用框架，本地是固定步进同步实验；不是完整相同实现。 |
| [zlhahaha/moonsim@0.3.1](https://mooncakes.io/docs/zlhahaha/moonsim@0.3.1) | 确定性模型仿真、Sim/Rng/EventRecord、重放及网络/可靠性模型。 | `simulate、NetworkModel` | **中：仿真和模型测试相似**。本地没有对方的通用事件引擎和完整重放模型。 |
| [wcx789ll/moonsim@0.1.2](https://mooncakes.io/docs/wcx789ll/moonsim@0.1.2) | 确定性离散事件及分布式网络仿真，虚拟时间、丢包、带宽队列、轨迹。 | `simulate、NetworkModel` | **中：分布式网络仿真相似**。本地不含通用离散事件引擎；网络条件和可复现实验存在交集。 |
| [mokomoking2501/lockwire@0.1.0](https://mooncakes.io/docs/mokomoking2501/lockwire@0.1.0) | 确定性仿真/重放/故障注入，Instant、Duration、ClockRelation、VirtualClock、时钟域。 | `Timestamp、Clock、simulate` | **中：虚拟时钟和仿真基础设施相似**。工业现场总线运行测试底座，不能据领域不同排除时钟与仿真功能交集。 |
| [cauchyQ/moonbit-causalkit@0.1.0](https://mooncakes.io/docs/cauchyQ/moonbit-causalkit@0.1.0) | HLC、版本向量、因果时间、延迟/离线消息仿真。 | `Timestamp、ClockEvent、simulate` | **邻近：时钟和事件仿真概念相似**。逻辑/因果时钟与物理时钟同步解决的问题不同；不能据此认定同一 PTP 实现。 |
| [SCL-NN/moontracekit@0.2.0](https://mooncakes.io/docs/SCL-NN/moontracekit@0.2.0) | Lamport/向量时钟、happens-before 和因果缓冲。 | `Timestamp、ClockEvent（仅概念层）` | **邻近：逻辑时钟**。没有证据表明该包提供 IEEE 1588 或本地物理时间伺服。 |
| [Asterless/MoonPtime@0.1.2](https://mooncakes.io/docs/Asterless/MoonPtime@0.1.2) | POSIX 高精度时间、不可变时间表示、时间运算和格式化。 | `Timestamp、timestamp_parts、add/sub/abs` | **基础能力重合：时间表示和运算**。高精度时间基础能力已有包；不是 PTP 协议项目。 |
| [SupremeHuaji/ptime@0.1.0](https://mooncakes.io/docs/SupremeHuaji/ptime@0.1.0) | 皮秒精度时间、时间戳转换与时间运算。 | `Timestamp、timestamp_parts、add/sub` | **基础能力重合：时间表示和运算**。时间精度与接口不同，基础时间功能仍有交集。 |
| [iceBear67/time@0.1.2](https://mooncakes.io/docs/iceBear67/time@0.1.2) | 日期时间、Instant、Duration、时钟以及 JS/Native 支持。 | `Timestamp` | **基础能力邻近：日期时间和时钟**。日期时间库与 PTP 同步协议不同。 |
| [walkzzz/moondes@0.5.0](https://mooncakes.io/docs/walkzzz/moondes@0.5.0) | 事件队列、仿真时间、进程调度、资源和实验管理。 | `simulate（实验与时间推进层）` | **邻近：离散事件仿真框架**。通用仿真基础设施，未发现 PTP 实现证据。 |
| [dxh8888/moonleasekit@0.1.0](https://mooncakes.io/docs/dxh8888/moonleasekit@0.1.0) | 租约、fencing token、leader election、故障切换仿真。 | `select_grandmaster（只在选主这一抽象层）` | **邻近：选主与故障模拟概念**。租约/多数派选举与 BMCA 质量元组比较不同；不能认定 BMCA 重复。 |
| [lxyhgvb/moonbit-radioframe@0.2.0](https://mooncakes.io/docs/lxyhgvb/moonbit-radioframe@0.2.0) | 无线帧、链路仿真、安全、路由及 6LoWPAN。 | `NetworkModel、simulate` | **邻近：网络链路仿真**。无线协议领域不同；需避免把通用链路模拟宣传为生态空白。 |
| [CYang-dep/moonosc@0.2.0](https://mooncakes.io/docs/CYang-dep/moonosc@0.2.0) | OSC 编解码、NTP era-zero timetag 与 Unix 时间转换；时钟同步由调用者提供。 | `Timestamp、encode/decode（时间及报文概念）` | **基础能力邻近：二进制时间标签**。不是 NTP 时钟同步器，更不是 PTP 实现。 |
| [usagi-star/mooncap@0.1.0](https://mooncakes.io/docs/usagi-star/mooncap@0.1.0) | PCAP/PCAPNG 及常见网络协议离线解码。 | `encode/decode（仅二进制报文领域）` | **邻近：网络报文处理**。没有证据表明根文档列出的协议覆盖 PTP。 |
| [sbqrre/moonbit-mcu-hal@0.2.1](https://mooncakes.io/docs/sbqrre/moonbit-mcu-hal@0.2.1) | timer/RTC、外设抽象、虚拟硬件和确定性内存后端。 | `Timestamp、simulate（通用基础概念）` | **邻近：硬件时间与确定性模拟**。不能等同于 IEEE 1588 硬件时间戳或 PTP 协议。 |
| [mokomoking2501/MoonECAT@0.2.0](https://mooncakes.io/docs/mokomoking2501/MoonECAT@0.2.0) | EtherCAT 主站，文档列出 Distributed Clock、SYNC0 配置、FRMW 漂移补偿、传播延迟和 DC jitter profiling。 | `Clock::apply_sync、NetworkModel、simulate（漂移、延迟和同步目标）` | **较高：工业分布式时钟功能相似**。EtherCAT DC 与 IEEE 1588 协议不同；实际工业时间同步目标和部分功能相近，不能据协议差异排除。 |
| [mokomoking2501/isoproject@0.1.0](https://mooncakes.io/docs/mokomoking2501/isoproject@0.1.0) | ClockSyncGuarantee 枚举 NoSync/Causal/Windowed/Physical 以及链路能力模型。 | `Clock/NetworkModel（仅建模概念）` | **邻近：同步保证的声明模型**。能力声明不是时钟同步算法，没有证据证明它实现 PTP。 |
| [mokomoking2501/profinet_master@0.1.0](https://mooncakes.io/docs/mokomoking2501/profinet_master@0.1.0) | 工业 PROFINET 主站；snmp_feature_ieee_8021as_mib_optional API 和本地实时发送周期控制。 | `协议/时钟相关领域` | **标准名命中：未证实 PTP 实现**。802.1AS 可选 MIB 开关不等于 gPTP 协议实现；不能将该命中直接判作 PTP 重复。 |
| [hhxhhx78/moonbit-iec104@0.3.1](https://mooncakes.io/docs/hhxhhx78/moonbit-iec104@0.3.1) | IEC 60870-5-104 带时标报文、ClockSyncTransaction、clock_sync_object 和时钟同步命令策略。 | `ClockEvent、时钟同步目标、时间戳和报文编解码` | **中：工业时钟同步命令功能相似**。工业遥控的校时事务与 PTP 精密同步协议不同，但不能说工业对时功能在生态中不存在。 |
| [Lyllyl789/moon-kalman@0.2.1](https://mooncakes.io/docs/Lyllyl789/moon-kalman@0.2.1) | Kalman/EKF/UKF、传感器时间同步、异步传感器对时、Synchronizer 时间戳容差接受。 | `时间戳、同步/滤波建模概念` | **邻近：传感器时间对齐与滤波**。样本时间对齐和估计滤波不等于 PTP 物理时钟伺服，也不是本地 PI 算法重复证据。 |
| [mjfmjf879/moonbit_constraint@0.1.0](https://mooncakes.io/docs/mjfmjf879/moonbit_constraint@0.1.0) | 整数事件时间、确定性事件排序、队列/服务/维护仿真和 CI 重放。 | `simulate（确定性建模基础概念）` | **邻近：确定性离散事件模型**。约束求解/排队仿真领域不同，没有 PTP 实现证据。 |
| [didiLjf/moonorbit@0.2.1](https://mooncakes.io/docs/didiLjf/moonorbit@0.2.1) | Actor 框架包含串行化、远程路由和 network simulator。 | `simulate、NetworkModel（网络模拟概念）` | **邻近：Actor 网络模拟**。Actor 分发与 PTP 时钟协议不同；不据 network simulator 词语认定同一项目。 |
| [dgmlbtttt/iec104@0.2.1](https://mooncakes.io/docs/dgmlbtttt/iec104@0.2.1) | 索引和根文档描述 IEC104 协议栈与确定性变电站仿真，但根 README 仅指向项目说明。 | `协议编解码和 simulate（领域及基础概念）` | **邻近：工业协议和确定性仿真**。根文档信息较少，不能推定完整内部功能已排除，也不能认定它实现 PTP。 |

逐项正文摘录与来源路径见 [reviewed-neighbors.json](../research/2026-10-19/reviewed-neighbors.json)。对普通 HTTP 客户端的注入 Clock、Raft 的 term 逻辑计数、神经网络的 network simulator、reservoir 等子串命中进行了排除性复核；这些命中不能被当作 PTP 项目重复。完整自动命中保留在逐包结果中，不能把自动命中数等同于相似项目数。

## 当前代码为何不能支撑“零重合”的申报

- `Timestamp`（`moonbit-ptp.mbt:3` 起）提供秒/纳秒表示、归一化和加减，时间运算已有生态包。
- `Clock::apply_sync`（484 行起）和 `simulate`（573 行起）做偏移调整及简化 PI 控制；NTP 和 EtherCAT DC 已覆盖时间同步测量或漂移处理方向。不能把算法和协议的差异写成没有功能相似。
- `NetworkModel`（510 行起）明确包含前向/反向延迟、抖动、丢包，正好与网络及无线链路仿真包的能力部分相交。
- `select_grandmaster`（417 行起）是质量元组排序；当前发现的 Raft/租约选举与它不同，没有证据证明 BMCA 源码或算法实现重复。但选主这一抽象概念本身并非独有。
- 当前自定义紧凑消息编解码不是完整 IEEE 1588 标准报文。`encode_standard_header`（673 行起）只编码公共头；缺少完整消息体、标准解码、真实 t1/t2/t3/t4 交换和互操作验证。不能把尚未完成的标准能力算作已经交付的差异化成果。

## 未能读取的文档

- [BigOrangeQWQ/wit-wasi-clocks](https://mooncakes.io/docs/BigOrangeQWQ/wit-wasi-clocks@0.2.6)：unavailable。站点显示 Docs unavailable / Documentation assets could not be loaded。
- [BigOrangeQWQ/wit-wasi-io](https://mooncakes.io/docs/BigOrangeQWQ/wit-wasi-io@0.2.6)：unavailable。站点显示 Docs unavailable / Documentation assets could not be loaded。
- [CAIMEOX/原来可以发中文包](https://mooncakes.io/docs/CAIMEOX/原来可以发中文包@0.1.1)：unavailable。站点显示 Docs unavailable / Documentation assets could not be loaded。
- [illusory0x0/🐫](https://mooncakes.io/docs/illusory0x0/🐫@0.1.0)：unavailable。站点显示 Docs unavailable / Documentation assets could not be loaded。
- [moonbit-community/moongrep-skill](https://mooncakes.io/docs/moonbit-community/moongrep-skill@0.1.0)：unavailable。站点显示 Docs unavailable / Documentation assets could not be loaded。
- [tonyfettes/ssl](https://mooncakes.io/docs/tonyfettes/ssl@0.1.1)：unavailable。站点显示 Docs unavailable / Documentation assets could not be loaded。

重复访问记录见 [unavailable-retries.json](../research/2026-10-19/unavailable-retries.json)。其中 `wit-wasi-clocks` 与时钟基础能力有关，尤其不能把文档缺失视为已排除相似性。

## 后续处理建议与提交门禁

1. 当前版本先按“相似性风险未解决”处理，撤回 README 和合规材料中已满足非重合要求的表达；本次已同步修正文档。
2. 通用时间类型、通用仿真和基本网络损伤模型不能再作为生态空白或主要创新点。改名、换术语、增加 CLI/测试都不能消除已有功能交集。
3. 若继续 PTP 方向，应先对完整标准报文、correctionField 定点运算、two-step 与乱序/丢包关联、特定 profile 的 BMCA/数据集、真实报文及互操作等具体交付物做更深入查重，再决定是否收窄范围并实现。这里只是待研究的差异化方向，**尚未证明零相似，也没有在本次擅自改写项目**。
4. 若官方将任何基础能力交集都算不合格，需要先明确可以验收的判定粒度；所有协议库都会使用时间、编码或状态机，不能把这种宽泛条件包装成可由关键词扫描保证的事实。
5. 在满足可核实的差异化边界后，提交前仍需刷新全量索引、修复文档访问缺口并按完整章程核对。当前不能出具“肯定不会因相似而失败”的保证。

## 复核入口

- [完整模块索引](../research/2026-10-19/modules.json)
- [逐包读取状态、版本、哈希与命中摘录](../research/2026-10-19/page-audit.json)
- [全部自动命中的复核结论](../research/2026-10-19/screening-review.json)
- [统计摘要](../research/2026-10-19/summary.json)
- [重点项目语义对照与摘录](../research/2026-10-19/reviewed-neighbors.json)
- [补充设计/API 文档读取记录](../research/2026-10-19/supplemental-audit.json)
- [来源、数量和本地源码哈希](../research/2026-10-19/manifest.json)

在当前目录运行 `python3 scripts/audit_mooncakes.py` 可对本次保存的索引和正文快照重新筛查，并重试缺失的页面；脚本复用缓存，**不会自动刷新索引或已缓存页面**。新的提交日复查须另存当日官方索引和文档，不能把缓存重放冒充实时查重。运行 `python3 scripts/build_mooncakes_review.py` 生成重点摘录，`python3 scripts/review_mooncakes_hits.py` 生成命中复核记录，`python3 scripts/write_mooncakes_report.py` 生成本报告；语义判断需要人工维护。
