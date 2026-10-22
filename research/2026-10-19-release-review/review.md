# 实现修正后 Mooncakes 全索引差异复查

本轮于 **2026-10-19 21:43–21:57（Asia/Shanghai）**保存新的官方完整模块索引，并补查相对 [上一轮](../2026-10-19-final/review.md) 的所有新增名称及新版本，以及本轮新增观察窗口、关联生命周期和快照前提涉及的邻近方向。此文是公开证据审查记录，不是赛事原创性裁定。本轮没有发布任何包。

## 结果与覆盖

| 检查范围 | 本轮结果 |
|---|---|
| 实时官方全量索引 | 3,117 条，含 81 个 yanked；未过滤撤回模块 |
| 相对上一轮 3,114 条的变化 | 3 个新增名称、52 个更新版本；另 3 个同版本元数据变化；0 个名称删除 |
| 索引名称、简介、关键词筛查 | 3,117 条全部重新筛查 |
| 根文档证据 | 新读取 126 个；其余 2,991 个复用上一轮同名同版本正文与哈希，全部重新执行专项检索 |
| 根文档可用性 | 3,106 个正文可读，8 个明确不可用，3 个内容受限，0 个网络失败 |
| 公开发布源码 ZIP | 56 个成功，0 个失败；新增下载 19 个、哈希验证后复用旧 ZIP 37 个 |
| 源码文本扫描 | 5,992 个支持后缀文本文件，大小跳过 0 个；第三方代码未执行 |
| 语义复核记录 | 55 个新增/更新版本逐项说明；111 个根文档命中模块附处置；全部 56 个源码包保留文件清单和逐行命中 |

上述“全量”指官方最新模块索引和对应根文档证据集合。**本轮没有重新联网下载全部 3,117 个根页，也没有审阅全部 3,117 个模块的所有源码。**同版本旧正文保留明确 `evidence_mode`，没有把缓存证据冒充实时页面。索引下载 SHA-256 为 `3429a2377a107d7b684b314d8abb88619218b7d97082cdeac646d03b3f771a07`。准确时间及逐项路径见 [manifest.json](manifest.json)。

## 新增和变化包的处理

三个新增名称是 `any07557-wq/moonvcs@0.1.0`、`cstoooo/mooniso_lite@0.4.2`、`wiretokenbotca4491/wire_token@0.1.0`。分别属于版本控制、ISO 20022 XML 验证/对账和 HTTP token 字符语法校验，均补读根文档与发布 ZIP；没有定位 PTP two-step/BMCA 规则。解析、校验、对账及报告本身仍是通用能力交集。

52 个更新版本均保存新根页。其中 `DDD12345-D/moon-snmp@0.3.0` 是必须指出的功能邻近：它已有请求/响应 ID 关联、重试、超时和 stray-reply 处理。`zhangbowen2006/agentcanary@0.1.1` 有离线历史策略回放、会话窗口频率/预算、审批到期和证据来源；这些与本项目新增的观察状态和报告在抽象层有交集。其余更新涉及字体数据、压缩/哈希/I/O、SDK、界面、JSON 查询/补丁、文件传输、印刷排版及统计学习等；逐包结论见 [changed-package-review.json](changed-package-review.json)。未命中 PTP 词语不会被写成所有内部功能已排除。

## 本次特别核实的部分功能相似

| 现有项目 | 公开证据中的具体能力 | 与当前项目的交集与边界 |
|---|---|---|
| [xuting22/ntp@0.4.0](https://mooncakes.io/docs/xuting22/ntp@0.4.0) | 四时间戳偏移/延迟测量、报文、滤波和时间源共识 | 时间同步测量目标、时间差运算和基本公式相似；本项目限定 PTP correction 定点值、明确报文关联与 BMCA，不运行 NTP 或调钟。协议不同不能消除基础功能交集。 |
| [btlqql/moon_tracelens@0.3.0](https://mooncakes.io/docs/btlqql/moon_tracelens@0.3.0) | 离线日志、request_id 分组、排序时间线、时间桶与窗口比较 | 离线事件关联、时间线及 JSON 报告部分相似；不提供 PTP sourcePortIdentity/sequence/correction 或 BMCA。 |
| [xuting22/rinex@0.1.2](https://mooncakes.io/docs/xuting22/rinex@0.1.2) | 显式 GPS 日/小时观察窗、缺失 epoch 和间隔检查 | “显式观察窗 + 缺失不能忽略”已有类似设计；其规则是 GNSS 观测文件接收契约。 |
| [z2823253773-p/moontick@0.1.1](https://mooncakes.io/docs/z2823253773-p/moontick@0.1.1) | 固定采样计划的完整覆盖、缺失、重复、乱序、越界时间戳审计 | 时间窗口、重复和缺失诊断部分相似；不含 PTP 两步交换、correction 或 BMCA。 |
| [DDD12345-D/moon-snmp@0.3.0](https://mooncakes.io/docs/DDD12345-D/moon-snmp@0.3.0) | 请求 ID 关联、超时、重试、stray-reply | 请求响应和生命周期基础能力已有；协议及匹配字段不同。 |
| [Han-Wentao/mooniso8583@0.1.0](https://mooncakes.io/docs/Han-Wentao/mooniso8583@0.1.0) | STAN/金额/终端/币种/DE90 请求响应关联与报文校验 | 字段关联检查产品能力部分相似；支付协议字段与 PTP two-step/E2E 条件不同。 |
| [shangwuxi/moonradius@0.1.1](https://mooncakes.io/docs/shangwuxi/moonradius@0.1.1) | identifier/request-authenticator 关联、有界缓存、重传/冲突分类 | 关联键、重复处理和有界状态管理基础能力有交集；未见 PTP/BMCA。 |
| [Magic486/moonnetlink@0.2.0](https://mooncakes.io/docs/Magic486/moonnetlink@0.2.0) | seq 事务关联、DONE 完整快照、loss/stale 和重放 | 快照有效前提、不能把部分数据当完整、迹线重放的设计有交集；Netlink 对象事务规则与 PTP 不同。 |
| [mokomoking2501/concord@0.1.0](https://mooncakes.io/docs/mokomoking2501/concord@0.1.0) | 协议 AST、角色投影、trace-backed 监控及违规报告 | “协议一致性检查/迹线证据”产品类别相似；源码所见 AxisAuthority 消息模型没有 PTP 字段或 BMCA 规则。 |
| [wcj12314/moon-flow-guard@0.1.0](https://mooncakes.io/docs/wcj12314/moon-flow-guard@0.1.0) | 离线网络流/解码包审计、Finding、门禁和跨流行为 | 离线网络审计及报告类别部分相似。源码 `registry.mbt:5696` 的 `35063 => "ptp"` 仅 EtherType 0x88F7 名称查表；不是 PTP 消息解析、关联或 BMCA。 |
| [oyjh0381/moonipfix@0.1.0](https://mooncakes.io/docs/oyjh0381/moonipfix@0.1.0) | 模板驱动流遥测解析、Session/Observation Domain 状态及 Sequence 审计 | 有状态网络报文审计基础能力相似，具体协议与规则不同。 |
| [zhangbowen2006/agentcanary@0.1.1](https://mooncakes.io/docs/zhangbowen2006/agentcanary@0.1.1) | 离线观察历史策略回放、会话窗口、审批过期和来源证据 | 窗口/到期/证据报告抽象部分相似；执行的是 AI 工具策略，不是 PTP 报文规则。 |
| [yujieMamba/moonallen@0.1.0](https://mooncakes.io/docs/yujieMamba/moonallen@0.1.0)、[yyyt0807/moonbitemporal@0.2.0](https://mooncakes.io/docs/yyyt0807/moonbitemporal@0.2.0) | 定性时间区间约束/可检查见证；双时态修订区间/历史决策证据 | 时间区间、证据前提与决策复核有通用交集；没有所审范围的 PTP 关联或 BMCA 具体规则。 |

源文件、行号、ZIP 哈希见 [source-audit.json](source-audit.json) 和 [source-hit-review.json](source-hit-review.json)。`mokomoking2501/profinet_master` 的 802.1AS 命中仍是可选 MIB 能力字段；普通 follow-up 迭代文字、哈希/数值中的 1588 和操作系统窗口捕获词语已逐项分类。

## 不能据此作出的承诺

在本轮新索引、根文档证据和 56 个发布源码文本集合中，**没有确认与当前项目相同的“限定 PTP two-step/E2E 关联、correction 精确运算和限定 BMCA 数据集决策核验”核心组合实现**。这支持具体差异化范围的描述。

但当前项目确实与现有软件共享报文编解码、请求响应关联、显式时间窗、重复与超时处理、有界状态、离线审计和证据报告等能力。**不能把新增观察窗口/生命周期模块本身宣传为生态独有，也不能声称整个项目没有任何部分功能相似。** 用户字面“任何类似/重合都不允许”的条件没有被本审查证明满足；如赛事按这种粒度裁定，风险仍然存在。新增 CLI、测试数量或改名不会消除这些交集。

根页中 8 个明确不可用项目，以及 SNMP 无 README、Golem tools/FlowGuard build failed 三个内容受限项，均有对应发布源码 ZIP 审查；这仍不能替代完整仓库/所有子包/历史版本的穷举。未覆盖未发布实现、二进制协议逻辑、未选中的其余源码和索引取样后的新发布；没有进行全生态代码克隆检测或取得赛事官方原创性裁定。因此不能出具绝对零相似、永久唯一或不会因相似而失败的保证。

## 可复核证据

- [实时官方完整索引](modules.json)、[版本及元数据差异](index-delta.json)、[55 个变化版本处置](changed-package-review.json)
- [根页正文来源、哈希、读取方式和命中](page-audit.json)、[元数据命中](metadata-hits.json)、[111 个根页命中处置](screening-review.json)
- [56 个发布源码包的文件哈希和逐行命中](source-audit.json)、[源码命中语义处置](source-hit-review.json)
- [覆盖与限制摘要](manifest.json)、[统计](summary.json)
- [增量根页采集脚本](refresh_delta.py)、[只读 ZIP 扫描脚本](review_sources.py)、[处置清单生成脚本](finalize_review.py)

这些脚本以此轮已保存索引和明确基线重放，不会自动刷新索引；再次实时审查须另存新的官方索引，不能把缓存重放当成未来提交日的实时证据。
