# 当前架构（0.3.0）

单案例数据流为：JSON 文本 → 严格输入和资源校验 → PTP 固定报文解码 → 显式观察上下文校验 → 关联和选主声明核验 → 条件测量 → correction 账本及可选条件误差预算 → 带逐项证据的 Finding/Report。`commission` 把多个这样的完整案例作为检查点，在每个检查点把有效 BMCA selected Announce 绑定到四帧交换，再比较相邻、充分成立的上游身份。协议和判断逻辑使用 MoonBit；Node 适配器只负责有界文件读取、启动本地 JS 构建和退出码。

| 包/入口 | 职责 | 实际边界 |
|---|---|---|
| `wire/` | 五类固定 PTP body 编解码、长度/值域/模式检查 | IEEE 1588-2008 version octet `02`、transportSpecific `0`、固定 44/54/64 字节；未知 profile/TLV Unsupported；correction 保留为有符号 2^-16 ns 整数 |
| `observation/` | 校验观察分期、窗口、捕获时钟、完整性声明和正的分析预算 | 缺失 `epoch` 保持缺失；跨分期、跨窗口、跨捕获时钟和过期证据不会建立成功关联；预算是调用者政策，不能冒充标准 timeout |
| `exchange/` | 按 epoch/domain/source/sequence、requester 和显式 claim 核验 two-step/E2E 关联 | 支持乱序；重复或复用键、缺失元数据和过期证据不输出测量；只有显式设备关联声明才可把身份错配判为 Violation |
| `bmca/` | 在有效 Announce 快照中比较质量、路径、身份、端口并核对 observed selected | 要求同一观察上下文、决策时刻和正的 Announce 有效期；候选完整与 eligibility 是输入假设；不实现 foreign-master qualification 或完整 port-state BMCA |
| `metrology/` | 从已接受四帧重建 PTP correction 贡献账本，按显式外部上界计算 offset 条件区间和应用上限判定 | 使用精确 BigInt；不从四时间戳估计真实路径不对称，不认证预算来源；`within_limit/outside_limit/indeterminate` 与协议状态分别输出 |
| `commissioning/` | 将有效 BMCA selected sender/receiver 与当前交换来源、观察上下文和声明有效区间绑定，比较相邻检查点上游身份 | 需要 selection stability 与跨检查点 capture-clock continuity 声明；不跳过失败检查点，不计算故障切换时长或跨 GM offset 差 |
| `diagnostic/` | 四态 Finding 和总体状态汇总 | Violation > Unsupported > InsufficientEvidence > Pass；Pass 仅覆盖实际执行规则 |
| `evidence/` | 完整帧字段投影、具体关联比较、逐规则依据、测量操作数和执行范围 | 大时间戳、correction 和计算中间量以十进制字符串保真；区分协议参考与本项目证据政策，不声称 IEEE 认证 |
| `audit/` | JSON 解析、数量限制、观察/协议组合、调用 metrology 和报告序列化 | 严格拒绝未知字段、重复 key 和超限输入；保留本次实际 assumptions、观察上下文和 BMCA 声明；`error_budget` 为可选对象 |
| 根库 | 单案例与 commissioning 的文本输入、JSON 文本输出 | 原案例输入 `ptp-audit/v1` 和输出 `ptp-audit-report/v2` 保持；campaign 使用独立 `ptp-commission/v1` / `ptp-commission-report/v1`；原测量分子/分母不变 |
| `cmd/ptp-audit/`、`bin/ptp-audit.mjs` | `check` / `commission` JS CLI、stdout 和退出码适配 | 普通文件上限 1 MiB、严格 UTF-8；不在 Node 中实现协议规则 |

观察时间与事件时间分别承担不同职责。每帧 `capture_time`、`capture_clock_domain` 是捕获观察时钟，用于判断窗口、先后和过期；`event_time`、`clock_domain`、`direction` 是本地端口 rx/tx 事件元数据，用于 t2/t3 测量。包内 t1/t4 来自 Follow_Up/Delay_Resp 的 PTP 字段。两类时间即使碰巧取值相同，也不能互相替代。

输入中 `epoch` 可以在语法上缺省，语义上保持 `None`，不会补成 0。成功的关联、测量和 BMCA 决策核对要求显式给出同一分期、窗口和可比较的捕获时钟。`observation.windows` 记录窗口的 id、epoch、clock_domain、start/end 和 producer 的 `complete` 声明；`observation.policy` 记录预算来源、`sync_follow_up_ns` 和 `delay_response_ns`。预算接受正的 Int64 十进制字符串，兼容 Int32 范围的整数 JSON number；输出统一保留字符串以免舍入。正预算只约束当前离线分析，不推断 IEEE 设备定时参数。缺少报文时，窗口不足或未确认连续观察只能表示尚未观察到；完整窗口覆盖截止时间后才可表示在这项政策下已经过期。两种情况均不能单独证明设备违反协议。

`exchange/context.mbt` 还会按 capture_time 重放独立分区的 pending 状态，在截止点内以唯一 counterpart 消费关联，超过截止点时实际移除条目。重复键不会消耗 counterpart；Delay_Req/Delay_Resp 还需要唯一显式交换 claim 指明目标 master。结束窗口不足时保留 `EXCHANGE.STATE.PENDING`，完整观察越过截止点时输出 `EXCHANGE.STATE.EVICTED`；两者状态均为 InsufficientEvidence，避免把本地缓存过期包装成 IEEE 设备违规。

BMCA 额外要求 `snapshot` 中的 epoch/window/clock_domain、decision_time、announce_validity_ns、validity_source、validity_confirmed 和 capture_window_confirmed。每个候选的 capture_time 必须不晚于决策时刻，年龄不得超过声明的有效期，并与决策使用同一上下文。过期或跨分期候选使快照证据不足；审计不会静默丢掉候选后把剩余集合宣布为完整。通过这些前提后才执行数据集比较和 selected 声明核对。

每项 Finding 保留原有 rule/status/frames/offset/expected/actual/detail，并新增 `evidence` 和 `rule_reference`。证据中包含实际引用帧的头、body、字段字节偏移、观察元数据、左右关联字段值、本次 assumptions、窗口/预算和 BMCA 声明。缺失引用帧和重复 frame id 会分别列出，缺失值不能通过 `null == null` 建立关联。报告 `coverage` 去重列出本次实际产生结果的规则和各状态，没有执行的规则不会继承总体 Pass。规则依据链接到项目实现、LinuxPTP 符号、独立 TShark fixture 核对和逐规则来源登记；完整规范正文、公开解释冲突和认证边界仍如实保留，见 [逐规则依据](rule-traceability.md) 与 [独立 wire 验证](wire-reference.md)。

条件测量使用精确整数：

```text
N(t) = seconds(t) * 1000000000 + nanoseconds(t)
F = (N(t2) - N(t1)) * 65536 - Sync.correction - Follow_Up.correction
R = (N(t4) - N(t3)) * 65536 - Delay_Resp.correction
offset_ns = (F - R) / 131072
mean_path_delay_ns = (F + R) / 131072
```

报告展示 t1–t4 的来源、三项参与计算的 correction、未再次扣除的 Delay_Req correction、F/R 和最终分数。精确代数不代表绝对时钟精度：时间戳来源、路径对称和稳定相对速率仍为调用者假设；负的推算 mean delay 返回证据不足。

新增 `metrology` 对每项已接受测量重建未修正分子和每帧 correction 贡献。Sync、Follow_Up 对 offset 分子的贡献取负号，Delay_Resp 取正号；三个字段对 mean delay 分子的贡献均取负号；Delay_Req 的贡献为 0。重建结果必须与原 `Measurement` 所有整数相符。可选 `error_budget` 的四个时间戳绝对误差上界、三个 correction 聚合误差上界和全路径不对称绝对上界均以 scaled ns 字符串表示；相加得到分母 131072 上的区间半径。预算包含非空来源、假设及速率误差已纳入的明确确认。没有预算只输出账本，预算无有效前提则不出具应用精度结论。协议通过但应用区间在指定上限外仍保持协议 `Pass`，以独立 `assessment.verdict` 表达应用结果。

`commissioning` 的 step 嵌入一个原 `ptp-audit/v1` 案例，完整原报告位于 `case_report`。它在原案例总体通过后，解析已核验的 selected Announce，记录 immediate sender 与 grandmasterIdentity 的区别。绑定要求四帧的共同 master 等于 selected sender，Delay_Req 与本地端口等于 Announce receiver，且 domain、epoch、window、capture clock 一致。每帧捕获时刻不得早于决策，也不得超过声明的 selection stability 或选中 Announce 有效期；stability 区间须落在同一观察窗口内。拒绝绑定时保留原案例的合法算术，但 `accepted` 为 false。

最多 16 个 step；相邻 step 必须全部通过、观察同一 receiver/domain、确认捕获时钟连续且四帧捕获区间严格先后不重叠，才输出上游身份变化分类。分类区分上游端口不变、同 GM 下端口更换、相同端口上 GM 更换、端口和 GM 都更换；不推断中间发生了什么或测量恢复耗时。selection stability 明确涵盖 sender 和通告 GM 在闭区间内均不变；不同身份的确认区间重叠属于声明矛盾。输入语法错误、未知字段和资源上限具有独立诊断，不生成部分通过的 campaign。顶层 `operational_acceptance` 与诊断 `status` 分开，区分证据链未接受、预算未评估、限内、限外及不确定；`timing_limit_verdicts` 保留逐 step 结果。完整操作数、条件区间和验收叙事见 [PTP 现场验收](commissioning.md)。

完整输入和可运行命令见 [完整交换与选主核验](../examples/complete-audit.md)。本项目没有通用网络仿真器、伺服调钟或通用日期时间库公共入口；单步、2019 minor version、802.1AS、P2P、unicast/alternate master 和未知 TLV 属于明确范围排除。旧模拟器保存在 `research/` 归档，不属于当前 API。
