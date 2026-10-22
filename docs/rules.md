# 规则和规范依据

当前范围为 IEEE 1588-2008 default multicast E2E two-step 的固定报文及数据集比较子集。依据包括已实际读取的 IEEE 官方解释、IEC 授权预览、IEEE 802.1 公开资料、LinuxPTP v4.4 独立实现参考和真实 TShark 解码。各来源承担的证据范围不同，见 [逐规则依据表](rule-traceability.md) 和 [官方来源登记](../research/wire-reference/sources/README.md)；不把实现或预览等同于完整规范正文。

95 个实现规则标识、规则测试和 BMCA 教程分支核对的证据范围见[规则与规范证据边界](normative-evidence.md)。规则数、测试通过及教程旁证均不构成完整 IEEE 符合性证明。

| 规则组 | 实际执行 | 依据/边界 |
|---|---|---|
| WIRE / SCOPE | 34 字节头、五种固定 body 44/54/64 字节、版本 02、类型/control、messageLength、保留字段、port、纳秒、flags 范围 | 官方预览定位 Clause 13/Table 18/25–28，IEEE802 资料重现 header offsets；LinuxPTP 旁证；五类实际 fixture 的独立 TShark 130 项字段检查通过。未知 profile/TLV/模式 Unsupported |
| WIRE.TWO_STEP_FLAG | 本范围非 Sync 的 twoStepFlag 置位返回字段 Violation | IEEE 1588-2008 官方解释 #11 p7 明确 Follow_Up 复制 Sync flags 时 twoStepFlag=FALSE；Pdelay_Resp 不在支持范围 |
| SCOPE.CORRECTION_TOO_BIG | INT64_MAX 与 -1/all-ones 均不参与测量，返回 Unsupported | 官方解释 #25 p21 与 #27 pp23–24 对 tooBig 编码存在冲突；同时排除两值是保守支持政策，不声称某一个是唯一明确规范 sentinel |
| EXCHANGE.SYNC_FOLLOW_UP | 显式 epoch/window、domain、sourcePortIdentity、sequenceId、Sync twoStepFlag 唯一关联 | LinuxPTP `port.c` 的匹配和 two-step 处理；epoch/window 是本项目输入证据，不是 PTP wire 字段 |
| CLAIM.E2E_IDENTITY | 请求方、响应来源、domain、epoch、sequence 一致 | LinuxPTP `process_delay_resp` 的身份/序号检查；明确设备声明后才可判断错配违规 |
| MEASUREMENT.EVIDENCE / AMBIGUOUS | 真实来源声明、相同时钟域、rx/tx、t1..t4、唯一键、路径对称和稳定相对速率 | 本项目安全前提；不声称读取文本就能认证采集事实 |
| MEASUREMENT.E2E | scaled-ns 精确代数；请求 correction 不重复扣除 | LinuxPTP `port_synchronize` / `process_delay_resp` correction 处理；Python Fraction 独立预期值 |
| METROLOGY.LEDGER / ERROR_BUDGET | 重建已接受四帧的原始与修正操作数、逐帧 contribution；条件误差区间和门限 verdict | 项目 PTP 代数解释及有来源的调用者误差模型；独立 Python struct/Fraction 校核。普通区间/门限不是项目独有，也不是 IEEE 的精度要求 |
| COMMISSION.* | 将有效 selected Announce sender/receiver/GM、时限、观察上下文绑定到完整交换；相邻观察分类并拒绝矛盾稳定区间 | 项目离线巡检证据政策。选择稳定和捕获时钟连续性需外部证据，不推断完整端口状态、故障切换时长或 servo 收敛 |
| BMCA.DIFFERENT_GM | priority1、class、accuracy、variance、priority2、GM id | IEEE 官方解释 #31 p28 确认 Clause 9.3.4/Figure 27 的质量优先级；独立编译 LinuxPTP `dscmp`，双向字段向量 |
| BMCA.SAME_GM | stepsRemoved、oneHop receiver/sender、sender、receiver port | 独立编译 LinuxPTP `dscmp2`，含拓扑结果及 error1/error2 |
| OBSERVATION / EXCHANGE.STATE / DEADLINE | 显式 epoch/window/clock/capture time、策略来源、freshness/deadline budget 和有界关联过期淘汰；区分未观察完与窗口已越过截止 | 本项目证据政策。缺少可比较时间域或窗口时不足以判过期；完整窗口内的观察过期也不能单独证明设备违规 |
| BMCA.EVIDENCE / SNAPSHOT / OBSERVED_DECISION | 候选完整/qualified、Announce 有效期及来源、连续窗口、同 epoch/clock、decision time 和 observed selected | 缺失、跨 epoch/window、未来或过期的 Announce 返回 InsufficientEvidence；有效性和采集真实性是调用者声明；不实现完整资格判定或端口状态算法 |
| INPUT / RESOURCE | JSON shape/key、各类预算、类型 API 值域 | 本项目资源和输入规则，不包装成 IEEE 原创算法 |

每条报告含实际执行的规则名；总 Pass 只表示执行到的范围内规则通过。单步同步、2019 minor version、802.1AS、P2P、unicast/alternate master、TLV、Announce 资格及完整端口状态均不在当前支持范围。

`WIRE.RESERVED` 检查针对“发送的固定报文字节是否满足零保留字段”以及本项目 canonical 输入范围。公开 IEEE802 资料说明发送为 0、接收忽略；产品拒绝继续使用该输入不等于声称 IEEE 要求设备接收端丢弃它。source/requester 的 1..65535 是 UInt16 非零输入边界；官方解释 #21 只确认实际端口为 1..N，而输入没有设备 `numberPorts`，故不认证该端口在真实设备上存在。

独立工具 wire 核对已经完成，显式观察分期、窗口/过期、BMCA 有效快照和证据明细均已有代码实现。完整规范复核仍有明确缺口：纳秒上限的正文、完整 control/flag/profile 值域、Clause 11 完整关联和异常语义、same-GM 全部拓扑分支，以及 tooBig 解释冲突的最终规范裁决。报告按每条规则列实际字段、上下文和来源，但不能由字段齐全推断规范全文已取得或完整 IEEE 一致性已经通过。逐项状态见 [计划核对表](plan-requirements-audit.md)。
