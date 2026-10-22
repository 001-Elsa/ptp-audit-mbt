# PTP 现场验收：从报文关联到有条件的偏差判断

本地增强保持版本 0.3.0。它把已接受的 PTP four-frame 交换继续用于两个实际问题：某次计算中的 correction 是否取错、漏扣或重复扣除；设备声明选中的主时钟，是否与实际用于测量的交换属于同一来源。协议输入仍为 `ptp-audit/v1`，输出仍为 `ptp-audit-report/v2`。已有输入不用添加误差预算，也能得到原来的协议检查和测量；报告新增 `metrology`。

适合的工作方式是离线导出原始 PTP payload，再填写明确的设备决策和采集元数据，复现一次同步异常或交付验收。工业控制网、音视频网络、实验室 PTP 软件栈都可能遇到这类问题；本工具只支持文档列出的 IEEE 1588-2008 default multicast/E2E/two-step 子集，不因此自动覆盖这些行业使用的其他 profile。

## 1. correction 账本解释“数值为什么变了”

原有测量给出 offset 与 mean path delay。新增账本分别保留未施加 correction 的结果、每个 PTP 字段对两个结果的带符号贡献，以及修正后的结果。每项引用具体帧号；计算使用 BigInt，输出分子和固定分母 131072，单位为 ns。

设 `cs`、`cf`、`cr` 分别为 Sync、Follow_Up、Delay_Resp 的有符号 correctionField 原始整数，单位为 1/65536 ns；`O0`、`D0` 是未修正结果的分子。账本验证：

```text
offset_numerator     = O0 - cs - cf + cr
mean_delay_numerator = D0 - cs - cf - cr
offset_ns            = offset_numerator / 131072
mean_path_delay_ns   = mean_delay_numerator / 131072
```

Delay_Req.correctionField 仍显示在账本中，`included: false`，两个贡献均为 0。它不会在已使用 Delay_Resp correction 的 reverse 路径上再次扣除。账本针对本项目支持的 E2E 操作数组合，不将这一处理泛化到所有 PTP 消息模式或 profile。

[`complete-audit.json`](../fixtures/complete-audit.json) 的四帧例子可以直接看到这项区别：

| 项目 | offset 贡献／结果 | mean delay 贡献／结果 |
|---|---:|---:|
| 未施加 correction | 25 ns | 275 ns |
| Sync：−0.5 ns correction | +0.25 ns | +0.25 ns |
| Follow_Up：+0.25 ns correction | −0.125 ns | −0.125 ns |
| Delay_Resp：+0.75 ns correction | +0.375 ns | −0.375 ns |
| Delay_Req：999999 scaled ns | 0，未参与 | 0，未参与 |
| 修正后 | 25.5 ns | 274.75 ns |

使用者因此可以核对被测实现自己的操作数：如果它报告的 offset 与账本不同，应沿具体字段和符号检查，而不能只看到一个笼统的“偏差异常”。账本重建时会再次检查四帧身份、观察标签、时间戳来源和已接受测量的整数一致性；它依赖原交换审计建立完整窗口和测量前提，不是绕过审计的替代入口。

## 2. 用显式误差预算判断是否足以作出验收结论

精确整数计算解决数值保真，不能证明硬件时间戳准确。可选 `error_budget` 允许调用者给出有来源的保守上界，再把测得的 slave-minus-master offset 表达为有条件区间。输入示意：

```json
{
  "timestamp_error_bounds_scaled": ["131072", "131072", "131072", "131072"],
  "correction_error_bound_scaled": "131072",
  "path_asymmetry_bound_scaled": "1310720",
  "offset_limit_scaled": "6553600",
  "source": "synthetic-example-bounds-not-device-calibration",
  "assumptions": "Constructed example only: each timestamp <=2 ns; aggregate correction <=2 ns; abs(forward delay - reverse delay) <=20 ns; rate error included.",
  "relative_rate_bound_confirmed": true
}
```

所有数值均为以 1/65536 ns 为单位的非负、规范十进制整数字符串；每个字符串最多 256 字符。`timestamp_error_bounds_scaled` 恰好四项，顺序为 t1、t2、t3、t4。每项必须已经包含本次交换期间相关速率误差的上界；`relative_rate_bound_confirmed` 必须显式确认这一点。`source` 和 `assumptions` 需要非空说明，但字段存在并不认证其真实性。调用者应从设备规格、采集链路标定或外部实验取得上界；本工具不会从四个时间戳反推出这些上界。

`correction_error_bound_scaled` 是三个实际参与计算的 correction 操作数的误差绝对值之和上界；它是误差界，不是 correction 本身的总值。`path_asymmetry_bound_scaled` 限定 `abs(forward_path_delay - reverse_path_delay)`，不是任何单向路径延迟本身，也不是一个从报文中估计出的真实不对称量。`offset_limit_scaled` 是本次应用允许的 offset 绝对值上限，不是 IEEE 标准规定的统一指标。

用 `u1..u4`、`uc`、`a` 表示这些 scaled 上界，条件区间在相同分母上计算为：

```text
C = corrected_offset_numerator
R = u1 + u2 + u3 + u4 + uc + a
offset_interval_ns = [(C - R) / 131072, (C + R) / 131072]
limit_numerator = 2 * offset_limit_scaled
```

这是保守绝对界的三角不等式传播，不是统计置信区间，也没有假设各误差独立或正态分布。上述构造预算的半径为 15 ns，因此 offset=25.5 ns 时区间为 [10.5, 40.5] ns。对 ±100 ns 的应用上限，整个区间落在范围内。

| `assessment.verdict` | 可支持的判断 | 使用者下一步 |
|---|---|---|
| `within_limit` | 条件区间整体包含在允许范围内，含等于边界 | 保留预算来源、完整输入和报告，作为这次声明前提下的验收证据 |
| `outside_limit` | 条件区间整体位于允许范围外 | 检查本次 PTP 关联、correction 账本及设备实现；结果仍依赖预算真实性 |
| `indeterminate` | 条件区间与边界相交，不能明确接受或拒绝 | 改善采集或标定信息，缩紧有依据的上界后重检；不能仅修改预算数字以获得通过 |

协议 `status` 与应用预算判断分别输出。一个四帧关联正确、账本一致的案例，可以是 `Pass`，同时预算为 `outside_limit`；这表示应用精度目标未满足，并不凭空增加一条 IEEE 协议违规。预算不完整、速率误差未确认或没有已接受交换时，不会产生精度验收结论。缺省 `error_budget` 时 `assessment` 为 null，`assessment_state` 为 `not_assessed`。

## 3. 将有效 BMCA 决策和实际交换来源连起来

`check` 核对单次审计输入。新增 `commission` 用于带显式声明的 PTP 验收流程：每个检查点包含一个完整审计案例，先建立有效 Announce 快照和 BMCA 比较结果，再核对用于测量的 Sync／Follow_Up／Delay_Resp 的共同 master 是否就是这次声明选中的 Announce sender。相同 grandmasterIdentity 后面仍可能有不同边界时钟端口，因此核对使用明确的 sourcePortIdentity，不能只比较 GM 字符串。

| campaign 字段 | 具体内容与前提 |
|---|---|
| `schema` | 固定为 `ptp-commission/v1` |
| `steps` | 1–16 个检查点；每个含唯一、非空 `id`，以及完整 `case: { ...ptp-audit/v1... }` |
| `steps[].selection_stability` | `source`、`confirmed`、`until: {seconds, nanos}`；来源声明同一 receiver/domain 在闭区间 [decision_time, until] 内，selected upstream sender **及其通告的 grandmasterIdentity** 都保持不变，不仅仅是端口状态或 sender 不变 |
| `capture_clock_continuity` | `source`、`confirmed`；相邻检查点身份分类还需要来源声明使用连续的同一捕获时钟。单个 step 的绑定不依赖跨 step 连续性 |

语法上可省略两类声明，语义上不会自动补齐。缺少选择稳定性不能接受该 step 的绑定；缺少捕获时钟连续性时，成立的单 step 可以保留，但相邻变化结论为证据不足。

campaign 还会对所有自身已通过的 step 两两检查稳定性声明是否相容，16 个 step 最多检查 120 对。比较的前提是相同 receiver、domain、capture clock，且已确认捕获时钟连续；若不同 upstream sender 或不同 GM 的两个确认闭区间重叠，报告 `COMMISSION.TRANSITION.CONTRADICTORY_STABILITY`。这项检查覆盖非相邻 step，也不要求两组 quartet 捕获区间有特定先后：单个检查点的证据可以分别成立，但中间加入另一个检查点不能消除已声明稳定区间的矛盾。

`selection_conflicts` 只记录实际冲突项，每项含 `from_step`、`to_step`、具体 `finding` 及双方 selection 证据，`evidence.transition_inferred` 固定为 false。发现冲突使总体为 Violation、`operational_acceptance` 为 `evidence_not_accepted`。这一检查核对整批输入的前提一致性，不会建立非相邻的切换结论；`transitions` 仍只保留相邻 step 的结果，失败 step 也不会被跳过。相邻冲突可以同时出现在相邻 transition 诊断和整体冲突表中，二者分别说明局部变化判断和整批声明的一致性问题。

它要回答的是：“设备说自己在用 B 的选主结果，现在提交的完整交换还来自 A 吗？”这将原本分开的 Announce、BMCA 和四帧测量连接成同一次可审查的 PTP 证据。输入缺失、候选不完整、Announce 失效、交换没有通过原审计时，工具保留证据不足或原审计失败，不能据几个相同身份字段给出验收通过。

相邻检查点只解释所声明选择的身份变化及各自证据，不将两次检查点之间的时间差称为故障切换时长。它也不对不同 GM 下的 offset 相减后宣称时钟跳变；不同 master 的时间基准是否可比较需要额外证据。CLI、完整输入和正反例见[可运行验收示例](../examples/commissioning.md)。

campaign 的 `status` 表示整条证据检查链的诊断状态，`operational_acceptance` 另外汇总应用预算。证据链未通过时为 `evidence_not_accepted`；链条通过后，任一已评估测量 `outside_limit` 则汇总为 `outside_limit`，否则存在 `indeterminate` 则保持不确定；只有全部测量都有预算且均 `within_limit` 才汇总为 `within_limit`。缺预算为 `unassessed`。`timing_limit_verdicts` 保留逐 step 的结果和绑定证据状态，避免从总体 Pass 推断精度验收通过。

## 4. 实际使用和差异边界

有价值的交付是“选主证据 → 交换来源 → correction 操作数 → 条件应用结论”这一条 PTP 专用检查链。其每一步都保留失败或前提不足的状态，不通过增加报告字段掩盖原先未成立的测量。

账本、误差传播、区间比较、时间线、字段关联和结构化报告本身都有通用先例。Mooncakes 的 `LunarUncertainty`、`moonbit_metrology` 是误差／计量邻域，`tideweave` 是时间窗口邻域，`joinwitness` 是组合键和见证邻域；这些基础能力不应被宣传成独创。这里继续扩展的是具体 PTP 消息、correctionField 参与关系、有效 Announce 决策和交换来源之间的约束及可复现用途。当前版本的对照范围与剩余交集仍以[相似性复查](non-overlap-current.md)为准。

所有随附演示均为人工构造 fixture，不是设备抓包、现场标定或硬件精度验证。完整授权 IEEE 1588-2008 正文尚未取得；这些能力不构成完整规范一致性审定、认证、真实路径不对称识别或绝对时钟精度证明。
