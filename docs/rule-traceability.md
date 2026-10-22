# 逐规则依据和边界

规则标识清单及 22 项规则测试、19 项 BMCA 教程分支测试的运行证据见[规则与规范证据边界](normative-evidence.md)。清单覆盖登记的规则标识，不表示所有输入分支穷尽，也不替代尚未取得的完整授权规范正文。

这张表把当前产品的可报告规则分成三类：**官方来源直接确认**、**独立实现/工具旁证**、以及**本项目的证据政策**。第三类不是 IEEE 要求；第二类也不是规范认证。完整 IEEE 1588-2008 正文和勘误没有纳入本地项目，因此表中仍保留明确缺口，避免把实现交叉核对写成逐条一致性证明。

官方资料登记和访问限制见 [`research/wire-reference/sources/README.md`](../research/wire-reference/sources/README.md)。固定 wire 样本由真实外部 TShark 验证，见 [`wire-reference.md`](wire-reference.md)。

| 规则/规则族 | 当前实现和证据 | 可确认的规范依据 | 未能确认或适用边界 |
|---|---|---|---|
| `WIRE.HEADER_LENGTH`, `WIRE.MESSAGE_LENGTH`, `WIRE.BODY_LENGTH` | `wire/wire.mbt` 检查 34 字节公共头、固定 44/54/64 字节和声明长度；TShark 对六帧独立解码 | IEC 61588:2009 官方预览目录定位 Clause 13、Table 18/25–28；IEEE 802.1 公开 contribution 重现 Table 18 偏移 | 预览不是完整正文；不能由目录单独证明每个 body 的所有长度或拒绝语义 |
| `WIRE.FIELD_RANGE`, `WIRE.TIMESTAMP`, `WIRE.NANOSECONDS` | 检查 48 位秒和纳秒输入范围；TShark 解码样本值 | IEEE/IEC 官方预览目录定位 Timestamp 和消息格式；`research/implementation-reference` 和独立工具旁证布局 | `nanoseconds < 1e9` 尚未从完整规范正文逐条确认；保留为实现安全约束，不称完整规范证据 |
| `WIRE.CONTROL`、`WIRE.RESERVED` | 检查 fixed control、保留字节和 canonical input；TShark 样本核对 control 和 zero fields | IEEE 802.1 contribution p2/p4：reserved 用于未来版本、发送为 0、接收忽略；Table 18 common-header offsets | 本产品把非零保留字节报告为输入/wire 违规，不能声称接收端依规范必须拒绝；control 枚举仍需完整正文核对 |
| `SCOPE.VERSION`, `SCOPE.PROFILE`, `SCOPE.MESSAGE`, `SCOPE.TLV`, `SCOPE.FLAGS`, `SCOPE.MODE` | 明确只收 IEEE 1588-2008 default/E2E/two-step 固定子集；未知扩展返回 Unsupported | 官方资料确认 Clause 13 的消息格式范围；TShark 能独立识别 v2 五类消息 | profile/flag 排除是本项目边界政策，不是“所有标准 profile 均不合法”；完整 flag 表和 profile 资格未逐条复核 |
| `WIRE.TWO_STEP_FLAG` | 已实现：本范围非 Sync 消息设置 twoStepFlag 时返回字段 Violation；Follow_Up、Delay_Req、Delay_Resp、Announce 均不能被误作双步 Sync | IEEE 1588-2008 interpretations #11 p7 核实 Follow_Up 复制 flags 时 twoStepFlag=FALSE，并指出 Table 20 的适用消息 | Pdelay_Resp 不在产品支持范围；仅凭解释文档不能替代完整许可正文 |
| `SCOPE.CORRECTION_TOO_BIG` | 已实现：`INT64_MAX` (`0x7fffffffffffffff`) 和 `-1`/all-ones (`0xffffffffffffffff`) 均返回 Unsupported，不参与交换测量；其他普通有符号 correction 保留亚纳秒分量 | IEEE 1588-2008 interpretations #25 p21 与 #27 pp23–24 | 两个官方 response 的 sentinel 文字冲突；同时排除两值是项目保守范围政策，不声称 `-1` 唯一或无条件是规范 sentinel，需许可正文/勘误裁决 |
| `WIRE.SOURCE_PORT`, `WIRE.REQUESTER_PORT`, `WIRE.RESPONSE`, `WIRE.ANNOUNCE`, `WIRE.BODY_KIND`, `WIRE.HEX` | canonical hex、body/header 一致性、source/requester port 1..65535 和身体各字段类型检查 | IEEE interpretation #21 pp14–15 确认 portNumber=1..N，N=`defaultDS.numberPorts`；独立 TShark 核对实际身份与 body | 1..65535 是本项目 UInt16 非零输入边界；输入未提供 `numberPorts`，因此不能证明端口实际存在，不能称 65535 普遍是合法设备源端口；其它 body 值域仍以实现和工具旁证为限 |
| `CLAIM.SYNC_FOLLOW_UP`, `EXCHANGE.SYNC_FOLLOW_UP` | 按 epoch、domain、source identity、sequence、two-step 及显式 pair claim 关联；有乱序/重复/回绕 fixture | LinuxPTP v4.4 `port.c` 是实现旁证；解释 #11 确认 Sync/Follow_Up two-step 方向 | Clause 11 的完整关联和异常语义尚未用完整正文逐条复核；epoch 是输入观察上下文，不是 PTP wire 字段 |
| `CLAIM.E2E_IDENTITY`, `EXCHANGE.DELAY_CONTEXT` | Delay_Resp 检查请求方 identity、master/domain/sequence/epoch；错配案例有报告 | LinuxPTP v4.4 `process_delay_resp` 旁证 | 完整 Clause 11 设备行为、超时和 profile 细节未逐条取得 |
| `MEASUREMENT.E2E`, `MEASUREMENT.EVIDENCE`, `MEASUREMENT.PATH_ASSUMPTIONS` | Python `Fraction` 独立预期值；保留 2^-16 ns correction，要求 t1–t4、来源、域和路径假设 | correction 的 signed scaled representation 由 interpretations #25/#27 旁证；LinuxPTP correction 处理是实现旁证 | tooBig sentinel、绝对时钟误差、路径非对称不能从普通四时间戳唯一证明；这些是项目安全边界 |
| `BMCA.DIFFERENT_GM.*` | priority1/class/accuracy/variance/priority2/identity 逐字段比较；独立编译 LinuxPTP dscmp vectors | IEEE interpretation #31 p28 确认 Figure 27 / Clause 9.3.4 的 quality precedence；LinuxPTP 旁证 | 完整 dataset eligibility 和所有质量值编码仍需许可正文核对 |
| `BMCA.SAME_GM.*` | stepsRemoved、one-hop、sender、receiver port 分支，逐步 universal-winner 检查；LinuxPTP dscmp2 vectors | 官方解释仅确认 BMCA quality 顺序；IEEE 802/IEC 预览可定位 Clause 9.3.4/Figures 27–28 | same-GM topology 全部 branch 和 state semantics 尚未从完整正文独立核对 |
| `BMCA.EVIDENCE`, `BMCA.OBSERVED_DECISION`, `BMCA.SCOPE.CONTEXT`, `BMCA.SNAPSHOT.*` | 已实现候选完整/资格确认/observed selected、显式同 epoch/window/捕获时钟/decision time，逐 Announce 核对 age 和确认的有效期；缺少、跨分期、未来或过期时 InsufficientEvidence | 这是项目证据政策，保护“看到 Announce”不被误写成“知道设备选了谁” | Announce 有效期来源、连续捕获与候选完整性仍是调用者声明；产品不独立认证这些事实，也不实施完整 qualification/port-state BMCA |
| `OBSERVATION.WINDOW`, `OBSERVATION.POLICY`, `OBSERVATION.RESOURCE`, `EXCHANGE.WINDOW`, `EXCHANGE.SYNC_DEADLINE`, `EXCHANGE.DELAY_DEADLINE`, `EXCHANGE.STATE.*`, `CLAIM.*_WINDOW` | 已实现显式 epoch/window/clock/capture time、正数 freshness budget 和有来源的 deadline policy；缺省 epoch 保留 None；缺失关联区分 pending 与有窗口依据的 expired；有界关联状态提供过期淘汰 | 项目输入安全政策；interpretation #3 的 announceReceiptTimeout 2–255 仅提供标准背景 | offline JSON 窗口和预算不能冒充 IEEE 统一超时；即使完整窗口越过截止仍是观察证据不足，不能据此单独指控设备协议违规 |
| `INPUT.SCHEMA`, `INPUT.RESOURCE`, `EXCHANGE.RESOURCE`, `BMCA.RESOURCE` | 严格 JSON keys、深度/字节/帧/候选预算、边界 fixture | 项目资源和可重现性要求 | 这些不是 IEEE conformance 条款 |
| `WIRE.FIXED_BODY` | 组合入口在已支持消息解码通过后记录固定字段检查通过；具体条件来自上列 wire 规则 | 对应固定布局的官方位置、参考实现和工具旁证 | 汇总 Pass 不是“完整 Clause 13 或完整 IEEE 认证” |
| `CLAIM.MISSING_FRAME`, `BMCA.MISSING_FRAME`, `EXCHANGE.ORPHAN_FOLLOW_UP`, `MEASUREMENT.AMBIGUOUS`, `INPUT.FRAME_ID`, `INPUT.FRAME_METADATA`, `BMCA.CANDIDATE_UNIQUENESS` | 解析后验证引用、身份唯一性和元数据；避免用缺失/重复/部分解码输入拼装测量或候选集 | 项目输入和证据一致性政策 | 观察到重复/缺失通常不足以证明设备行为违规；明确设备声明与字段矛盾才另作核对 |
| `BMCA.SCOPE.DATASET`, `BMCA.SCOPE.NO_UNIVERSAL_WINNER`, `SCOPE.TWO_STEP`, `SCOPE.CASE`, `SCOPE.NO_SEMANTIC_CHECK` | 明确限定 dataset、单步不支持、输入 profile、没有执行语义规则等边界；不输出虚假全通过 | 本项目支持范围政策，dataset 部分参考 LinuxPTP dscmp/dscmp2 | 不把不支持的完整资格/BMCA/扩展场景转换为违反标准，也不把仅解码成功称整体通过 |

## 结论边界

新增 `METROLOGY.LEDGER`、`METROLOGY.ERROR_BUDGET` 与 `COMMISSION.*` 全部标记为项目代数解释或证据政策，已加入 [95 项实现清单](../research/normative-completion/rule-inventory.md)。它们不对应新增 IEEE shall：账本来自本项目已接受 PTP 四帧的代数展开；误差界/限值来自调用者；选主绑定需要独立的身份稳定声明和捕获时钟连续性。完整误差公式与闭区间稳定语义见 [commissioning.md](commissioning.md)，独立 Python struct/Fraction 校验及全部构造数据来源见 `research/commissioning/manifest.json`。

独立 TShark 130 项字段检查已经完成的是“这六个固定字节样本被外部 dissector 按 PTP v2 解释，并与独立契约相符”。它不能替代规范全文、硬件来源、报文关联、BMCA 设备状态或竞赛原创性审查。

当前来源事实支持把 common header 偏移、五类消息表位置、two-step Follow_Up 旗标、BMCA 质量比较顺序和 correction 的公开解释记录为可追溯依据；对于正文访问不到的 nanosecond 上限、全部 control 枚举、Clause 11 完整关联、same-GM 拓扑全分支、完整 profile 字段值域和 tooBig 冲突裁决，文档明确保留规范复核缺口，不得在报告中宣称“完整 IEEE 认证”。本轮在用户的 Downloads、当前项目及 Documents 的标准相关文档文件名中未定位到已授权完整 IEEE/IEC 正文；未使用来源可疑的第三方规范 PDF。

`CLAIM.AMBIGUOUS` 是项目证据政策：同一 Delay_Req 或 Delay_Resp 被重复或冲突的四帧声明引用时，返回证据不足且不输出相应测量。它避免把重复声明变成多次测量或唯一目标 master 的证据，不是 IEEE 对设备发送行为的违规判断。
