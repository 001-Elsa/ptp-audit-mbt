# 当前版本 Mooncakes 相似性复查

本页记录当前 0.3.0 的功能对照和官方索引源码扫描范围。2026-10-20 新增的领域能力须结合本页新增近邻披露和最后源码冻结后的克隆结果阅读。早先基于 3,117 条索引及 56 个 ZIP 的报告是历史基线，不是本次最新覆盖；旧模拟器的分析继续保留在[历史报告](non-overlap.md)。本轮审查不会把未确认改写为不存在，也不会代替赛事原创性裁定。

## 当前索引与源码扫描

2026-10-20 11:34:58（Asia/Shanghai）从 Mooncakes 官方接口捕获索引，含 **3,140 个唯一模块/版本条目**。扫描器 v4 对索引列出的当前版本逐包读取所有 ZIP 成员：**3,140/3,140 状态均为 `ok`**，共 **284,094 个文本文件、3,587,979,940 字节文本**；归档下载共 1,297,116,902 字节，解包成员总计 4,544,106,611 字节，另登记 6,301 个二进制成员。此范围是索引列出的当前版本，包含 yanked 条目，不覆盖所有历史版本。

完整清单、原始索引和逐文件 hash 见 [full-source-audit](../research/full-source-audit/README.md) 与 [manifest](../research/full-source-audit/manifest.json)。独立重验重新检查了 3,140 个归档及 290,395 个普通 ZIP 成员的 SHA-256，并通过；结果见 [verification](../research/full-source-audit/verification.json)。关键词扫描只用于定位候选，关键词出现不等于功能实现，未命中也不证明语义不存在。逐包语义处置和源码克隆筛查结果应与本索引版本绑定后阅读；它们不是官方原创性判定。

## 按功能对照

| 当前产品功能 | 已确认的生态交集 | 本轮已读证据能支持的区分 | 结论边界 |
|---|---|---|---|
| 五类 PTP 固定报文的 header/body 解码（Sync、Follow_Up、Delay_Req、Delay_Resp、Announce） | `hevienz/moonbit_libbpf` 发布的 `vmlinux.h:118785–118807` 含标准 packed `ptp_header`、clock/port identity、domain、correction、sequence 等公共头字段布局。`oboard/mocket` 也含 Mongoose XMC7/STM32F 硬件 PTP timestamp 寄存器布局声明（[硬件上下文复核](../research/originality-completion/mocket-hardware-ptp-context-review.json)）。这些都是实际 PTP 结构交集。 | 这些邻域证据分别是 Linux 内核类型声明和硬件寄存器布局；已读范围未确认它们实现本项目的五类 MoonBit payload 解码、输入边界和报告链路。 | 不得称生态中没有 PTP 字段或布局。保留标准 wire 结构是互操作要求；声明交集也不能被夸大成完整 PTP 解码器。 |
| 有符号 scaled-nanoseconds correction 与限定 E2E 测量 | NTP 项目有四时间戳 offset/delay 测量；EtherCAT 分布式时钟项目也有传播延迟、offset/drift 测量和补偿。时间测量和校正是实际功能邻域。 | 已读上下文未确认相同的 PTP correctionField 精确整数运算及限定 two-step/E2E 操作数组合。通用 offset/delay 公式不是独占算法。 | 只可说本轮检查的上下文尚未确认同一 PTP correction 核心；不能说精确时间测量完全没有类似功能。 |
| 四帧 Sync、Follow_Up、Delay_Req、Delay_Resp 身份关联 | 多个包实际具有 request/response ID 关联、pending 生命周期、接收窗口、重复/迟到处理或 deadline 检查，包括 SNMP、JSON-RPC、ISO8583 和离线 VCD 波形断言。 | 已读上下文未确认同一 PTP 的 domain/source/sequence/requester 身份键、乱序 two-step/E2E 四帧组合及 correction 测量链路。 | generic 请求响应关联与窗口是明确交集；不能宣传这些基础能力独有。未确认的是所述限定 PTP 组合，不是任意形式的类似。 |
| 限定数据集上的 same-GM / different-GM BMCA 比较及有效快照前提 | 生态中有时钟源选择、NTP 共识、分布式时钟或时钟同步事务等邻近功能；BMCA 官方托管教程也公开说明比较流程。 | 已读源码上下文未确认与本项目相同的 PTP dataset 字段顺序、same-GM sender/receiver/stepsRemoved 分支及 Announce 有效快照证据核验组合。 | 时钟源选择和 BMCA 不能仅因都选出时钟就说功能相同，也不能据差异声称完全无类似。教程是非规范参考，不是完整 IEEE 正文。 |
| PTP correction 贡献账本与条件偏差区间 | `FrozenLemonTee/LunarUncertainty@0.1.1` 有独立误差 RSS 传播；`lsh775/moonbit_metrology@0.2.0` 有声明不确定度／容限判定；`gckbbrant/moonbitTolerance@0.3.0` 有保守区间、带符号贡献链、worst-case／RSS、贡献表及可接受性；`wjyupl/measure@0.1.2` 有相关误差传播、置信区间与报告。任意精度区间／有理数也有现成库。 | 本项目只对已接受的 PTP 四帧重建原始 offset／mean delay、逐帧 signed scaled correction 对二者的贡献，并明确 Delay_Req 贡献为 0；再将 t1–t4、聚合 correction 误差和完整路径不对称上界与该组帧的身份／前提一起输出。 | 计量、贡献表、区间和阈值不是独有；已读近邻未确认同一套 PTP 操作数、关联核验和条件区间链路。上界来自调用者，不能从四时间戳反推真实路径不对称。见[领域近邻源码阅读](../research/originality-completion/domain-enhancement-neighbor-review.json)。 |
| 有效 BMCA 选择到实际四帧 master 的绑定及相邻选择变化 | NTP／EtherCAT 有时钟源测量、选择或切换的邻近目标，`tideweave` 等有时间窗口／变化证据。 | 每个检查点先完成既有审计，按 BMCA 所选 candidate 的 Announce.sourcePortIdentity 绑定 Sync／Follow_Up／Delay_Resp 的直接发送 master，并单独报告 grandmasterIdentity；每帧须在决策之后及所声明稳定区间／Announce 有效期以内。在确认连续且同 receiver／domain／capture clock 的前提下，对全部已通过检查点两两核对稳定区间，拒绝非相邻区间也存在的矛盾；身份变化结论仍只连接相邻检查点，并单独区分 upstream 与 GM，不跨越被拒绝的检查点。 | 这是对明确输入声明的 PTP 证据核验，不是实际选主守护进程、完整 BMCA qualification、在线切换时长测量或跨 GM 时钟跳变量证明。已读近邻未确认同一具体链路。见[实用能力边界](commissioning.md)。 |
| 显式身份、完整性和窗口 | `JQ-ai-nb/joinwitness@0.1.0` 已有多字段组合键、来源 ID、重复拒绝、完整输入下的缺失证据；`LMK-ai-nb/tideweave@0.1.0` 已有 event-time 窗口、迟到／finality、重复／冲突 ID、确定性重放和 before/after 证据。 | 已读源码未确认 PTP 四帧、signed correction、Announce／BMCA；对方 `correction` 是事件替换，不是 PTP correctionField。 | 身份、窗口、缺失证据、确定性和报告不能单独列为独有。见[新增近邻源码证据](../research/originality-completion/registry-3138-delta-neighbor-review.json)。 |
| 精确运算和结构化报告基础 | `colmugx/json-schema@0.1.3` 有 BigInt 系数与 scale 精确算术；`marianoguerra/error-report@0.1.1` 有 severity／code／source spans／notes／JSON。 | 未确认这些包提供本项目的 PTP 具体操作数、身份链和 BMCA 前提。 | BigInt、精确结果、字节位置和 JSON 诊断本身已有明确交集。 |
| 通用请求/响应、观察窗口、deadline、过期生命周期和结构化报告 | 已确认多个项目实现请求/响应校验、窗口完整性、超时与迟到消息处理、离线协议审计或结构化错误/证据。例如 SNMP、MBOpenClacky、MoonISO8583、moonbit-vcd、MoonNetLab、http-async、MoonTSInspect、RINEX。 | 本产品把这些能力用于明确 PTP 捕获证据、两类交换关联、BMCA snapshot 和逐规则报告；具体领域用途不同不消除通用能力交集。 | 这些能力存在真实交集，应如实披露；不能把报告形式或 PTP 场景包装成基础能力独创。 |

邻域源码上下文审查记录于 [clock-neighbor review](../research/originality-completion/clock-neighbor-context-review.json)、[request/response neighbor review](../research/originality-completion/association-neighbor-context-review.json) 和 [coverage join](../research/originality-completion/final-neighbor-review-coverage.json)。最终 join 绑定 76 个 clock-sync 包的 232 条命中和 32 个 request-response/deadline 包的 58 条命中，保存的上下文命中均已逐项复核。报告限定其实际读取的代码上下文与扩读范围；没有逐行人工通读每个模块的全部代码。

全量强命中复核见 [full-source-semantic-review.json](../research/originality-completion/full-source-semantic-review.json)：264 条强或专项命中中 264 条已人工复核、0 条待审，涉及 24 个包。其余普通 `ptp_messages` 词语命中单独保留，不能把“强命中复核完成”说成所有源码都已语义通读。主扫描标记为 binary 的 6,301 个成员另行完整回读并核验 hash；247 个严格 UTF-8/control-byte 视图未增加关键词命中。64 个大文本候选作过完整逻辑行复核；NUL 源码/文档复核覆盖 212,839 个成员、23 个含 NUL 项。补扫明细见 [supplemental binary/text review](../research/full-source-audit/supplemental-binary-text.json)、[NUL review](../research/full-source-audit/text-source-nul-review.json) 和 [supplemental semantic join](../research/originality-completion/supplemental-source-semantic-review.json)。这些补充检查都受其登记成员和解码/候选范围限制。

本轮新增计量／选源方向另作[领域近邻核对](../research/originality-completion/domain-enhancement-neighbor-review.json)：对当前 3,140 个固定版本的 284,094 个文本、3,587,979,940 字节执行 uncertainty／error-bound／interval／clock-handover 目标词发现，251 个包产生 2,332 条“类别＋文件＋行”命中；同一行可属于多个类别。这是全量词检索范围，另有 12 个具体近邻的逐段源码实际阅读，二者不混同。原全量快照的 3,139 个同版本 ZIP／成员 hash 经确认复用，最后升级的 `moonfeed@0.1.1` 单独完成同规则搜索后重新连接当前清单。报告绑定本轮最终 `metrology`／`commissioning`／`audit` 源码 hash；通用误差预算、保守区间、贡献表、有理数和阈值判定确有已有实现，不能据本项目用于 PTP 就将这些基础能力列为独占。

## 源码克隆候选复核

本轮 PTP 计量与选源绑定代码完成后，重新冻结当前 **18 个生产 MoonBit 文件、33,149 个 token**，对固定索引的 **3,140 个当前版本包**完整重跑。外部侧纳入 **93,828 个生产文件、137,529 个总扫描文件、238,968,538 个 token**；其中识别的 4,966 个生成文件和 43,701 个第三方测试文件全部纳入。所有包恰好扫描一次，合并后重新验证本地源码、结果 metadata 和全部归档 hash；未解决包、有限源码清单和显式大小／编码排除均为 0。

这份筛查比较本地生产 MoonBit 与外部 MoonBit，覆盖新 `metrology` 和 `commissioning`；本地测试、JS／Python／shell 辅助工具及低于阈值的片段不在该生产源码筛查范围。UTF-8 及 BOM 明示的 UTF-16／32 严格解码，32 MiB 单文件上限保留为方法边界。它不是任意多语言语义等价证明。上一版本 3,123 包／15 生产文件的结果仅保留为[历史快照](../research/originality-completion/history/2026-10-20-pre-enhancement/README.md)。

低阈值 40 token/5 行得到 4 个文本候选，全部已逐项人工复核；高阈值 80 token/8 行由同一组最大匹配派生，候选为 0。四个较短候选分别是三个通用 JSON required-field getter，以及一个通用字典序比较器（对方用于音频 `Duration`、本地用于 PTP `PortIdentity`）。四个候选均来自既有 JSON getter 和 PortIdentity 比较器，新增 PTP 贡献账本、条件区间和选源绑定文件未产生达到门槛的候选。候选复核没有确认五类 PTP 报文、two-step/E2E correction 和 BMCA 组合的复制证据；它只处置报告中的词法片段，不证明语义绝无相似。数据及方法见 [40/5 report](../research/originality-completion/full-source-clone-screen-40.json)、[80/8 report](../research/originality-completion/full-source-clone-screen-80.json) 和 [candidate dispositions](../research/originality-completion/full-source-clone-human-review.json)。

此前产品手写十六进制 nibble helper 与两个生态包产生短片段候选；现已改用已核实的 MoonBit Core hex decoder，同时保留输入长度和首错偏移策略。旧的改前扫描与复核固定在 `before-remediation-full-source-clone-*`，不作为当前源码筛查结果。

## 规范与判定边界

完整、授权使用的 IEEE 1588-2008 / IEC 61588:2009 正文尚未取得，访问过程和官方路线记录在[来源访问记录](../research/normative-completion/source-access.md)。官方解释、IEC 预览、IEEE 802.1 托管教程、LinuxPTP 参考实现和 TShark 解码各自只支持明确记录的范围，不能合并成完整规范认证。用户要求的“不接受任何类似或重合”比本地章程副本中可读到的条款更严格；不能用章程措辞替用户放宽该门槛。

本地功能对照、关键词筛查、源码克隆候选检测都不能证明任意层面绝对零相似、永久唯一或赛事通过。已确认的标准头/寄存器布局、时钟测量邻域、请求/响应与窗口生命周期、离线审计及报告交集仍然存在。源码克隆筛查只测量规定阈值和当前版本源码内的 token/规范化块匹配，不能覆盖语义改写、所有历史版本、未发布代码或其他层面的功能相似。是否接受这些交集，以及完整规范/原创性判定，仍未由本地证据解决。
