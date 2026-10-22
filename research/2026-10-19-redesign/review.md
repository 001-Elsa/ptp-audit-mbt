# 本轮重新全量检查与大改候选评估

时间：2026-10-19（Asia/Shanghai）。本轮重新从官方端点取得索引，保存新目录并重新读取根文档；不是上轮缓存重放。最终摘要中的耗时仅是失败/不可用项重试与缓存汇总的耗时，不是整轮抓取耗时。

- 全量模块：3,113，含 81 个 yanked；与上轮相比无新增名称或版本变化。
- 根文档成功：3,105；网络/HTTP 失败：0；站点显示文档不可用：8。
- 首轮 11 个网络超时均已重试成功；不可用页也重复读取，保留初次结果以复核。
- 全部 46 个自动命中均附语义复核；新增 PTP 消息字段/关联词检索有 41 个根文档命中，所见为普通 follow-up/upstream 文字或应用后续消息 API，未检出 PTP 关联核验核心。
- 新方向相关的元数据候选：198，这是自动筛查集合，不声称对每个项目全部源码逐行人工审阅。
- 发布源码 ZIP：27 个，成功 27 个；检索 3,280 个支持后缀文本文件；因大小限制跳过 0 个。只在内存读取，不执行第三方代码。范围包含所有 8 个根文档不可用包的发布源码。

## 新方向的实际对照

| 已有包 | 已确认能力 | 对规划的约束 |
|---|---|---|
| xuting22/ntp | 偏移/延迟测量、NTP 报文与源选择 | 不做 NTP、通用同步测量库或实际调钟；新核心限定 PTP 的消息关联和决策规则 |
| MoonECAT / lockwire / fieldbus_core | 工业时钟、虚拟时钟、协议底座、场景与一致性工件 | 不另建现场总线底座、虚拟时钟或通用协议监测框架；其发布文本未检出 PTP/BMCA 核心 |
| profinet_master | IEEE8021AS 可选 MIB 支持声明 | 源码命中为能力标志、输出和测试，未检出 gPTP 实现；不能因出现标准名认定直接重复 |
| moonnet-lab / moonlab / moonsim / radioframe | 网络损伤与确定性仿真 | 移除当前仿真层，不以仿真或可复现为独有成果 |
| cghyyrrt/moonbit-pcap / usagi-star/mooncap | PCAP/PCAPNG 和网络报文解析 | 不做抓包格式解析，接收提取后的 PTP 负载与必要元数据 |
| CJR-ai-nb/evowitness | 结构化契约兼容性与最小 JSON 反例 | 不做通用 witness 框架或契约兼容性；报告和反例能力本身不能当作新颖点 |
| HhWw96/moontxnwitness | 事务历史、依赖环证据与复核 | 不做事务一致性或通用证书框架；仅实现明确的 PTP 规则 |
| length-super/moonctl | CTL 有限状态模型检查及反例路径 | 不做通用模型检查或性质 DSL；直接执行已定义的 PTP 语义规则 |
| vicTop-cw/mcpconftest | MCP 协议一致性探测与报告 | “协议检查工具”这一产品类别已有项目，区别必须落实到 PTP 具体规则，不能只换名称 |

## 源码检索结论与边界

在这些发布文本中，PTP/1588/BMCA/grandmaster/gPTP/correctionField 等命中未形成已确认同核心功能的实现：PROFINET 的 802.1AS 为 MIB 能力声明，1588 数字出现在随机数/测试/性能数据，follow-up 为普通后续事项描述。逐行命中位置和解释均已保存。

这支持把“PTP two-step 关联 + 限定 BMCA 决策核验”列为进一步研究候选，不能证明绝对无类似。基础字节处理、时间运算、规则校验和诊断报告与其他软件仍有抽象交集；并未对另外数千模块全部源码或历史版本进行克隆/功能穷举分析，也未穷举二进制 fixture。赛事原创性判定粒度及规范条款来源仍未完整核实。

**状态：候选方向未发现已确认同核心功能；用户字面零类似条件未被证明满足；不出具可提交保证。** 完整阶段与验收规划见 [大改方案](../../docs/redesign-plan.md)。

## 证据文件

- [新索引](modules.json)、[逐包正文状态/哈希/命中](page-audit.json)、[统计](summary.json)、[初次访问记录](initial-page-audit.json)
- [全部自动命中复核](screening-review.json)、[PTP 专项词命中](ptp-specific-hits.json)、[新方向元数据候选](domain-candidates.json)
- [重点项目根文档与链接](deep-review.json)、[发布源码逐包检索](source-audit.json)、[源码命中解释](source-hit-review.json)
- [来源摘要](manifest.json)
