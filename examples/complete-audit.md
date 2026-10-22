# 完整交换与选主核验

在项目根目录运行：

```sh
./bin/ptp-audit.mjs check fixtures/complete-audit.json
./bin/ptp-audit.mjs check fixtures/complete-audit.json --json
```

需要 Node.js 22 或以上和本地 MoonBit 工具链。CLI 会先构建 MoonBit JS 入口。完整输入为 [`fixtures/complete-audit.json`](../fixtures/complete-audit.json)，使用 `ptp-audit/v1` 和 profile `default-e2e-two-step-2008`；JSON 报告提升为 `ptp-audit-report/v2`，以区别 assumptions 从旧通用字符串数组变为本次实际对象的变化。退出码 0/1/2/3/4 分别表示已执行检查通过、违规、用法/文件/构建错误、证据不足、不支持的范围。

这是独立构造的协议 fixture：四帧 E2E 交换加两个 Announce 候选，不把它称为真实硬件采集。主时钟为 `0011223344556677:1`，从端口为 `8899aabbccddeeff:1`；Sync/Follow_Up 的 sequence 为 7，Delay_Req/Delay_Resp 为 31。两个消息族的序列号允许不同。五种消息的固定字节布局另由外部 TShark 核对，见 [独立 wire 验证](../docs/wire-reference.md)。

输入先明确观察上下文。每帧含 `epoch: 0`、`window: "capture-0"`、`capture_time` 和 `capture_clock_domain: "slave-monotonic-0"`；`epoch: 0` 是显式声明，不是缺失时默认补值。顶层 `observation.windows` 给出这个窗口的起止和 `complete: true`；`observation.policy` 的 `source` 为 `fixture-analysis-policy`，Sync/Follow_Up 与 Delay_Req/Delay_Resp 两项预算均为正的 1,000,000,000 ns。这是构造样例的本地分析政策，不是从 PTP logMessageInterval 推断的标准 timeout。实测采集应填写真实的连续观察范围和政策来源，不应照抄构造 fixture 的窗口声明。

预算可用正的 Int64 十进制字符串传入；兼容 JSON number 时要求在 Int32 范围，报告输出预算为十进制字符串。较大预算应写成字符串，不能依赖 JSON 浮点数保留任意 64 位整数。

`capture_time` 表示观察时钟，用于窗口和新鲜度；用于测量的 t2/t3 则来自 Sync/Delay_Req 上的 `event_time`、`clock_domain`、`local_port` 和 rx/tx `direction`。它们有不同用途，不能用捕获时间替代 NIC 事件时间。样例为方便计算让部分数值相同，并显式确认来源。

| 测量操作数 | 实际值与来源 |
|---|---|
| t1 | frame 2 的 Follow_Up.preciseOriginTimestamp：100 s + 1000 ns |
| t2 | frame 1 的从端口 rx event_time：100 s + 1300 ns |
| t3 | frame 3 的从端口 tx event_time：100 s + 5000 ns |
| t4 | frame 4 的 Delay_Resp.receiveTimestamp：100 s + 5250 ns |
| Sync correction | −32768 scaled ns，即 −0.5 ns |
| Follow_Up correction | 16384 scaled ns，即 0.25 ns |
| Delay_Resp correction | 49152 scaled ns，即 0.75 ns |
| Delay_Req correction | 999999 scaled ns；记录在证据中，不在 reverse 中再次扣除 |

forward = 300.25 ns，reverse = 249.25 ns，因此 offset = 25.5 ns、mean delay = 274.75 ns。报告保留 `offset_numerator: "3342336"`、`mean_delay_numerator: "36012032"`、`denominator: 131072` 和 unit `ns`；中间整数 F/R 分别为 `19677184`、`16334848`，单位为 2^-16 ns。计算不通过 Double 舍弃亚纳秒部分。

`assumptions` 的 `symmetric_path`、`timestamp_provenance`、`stable_rates` 都为 true。它们会作为本次实际输入回显，而不是仅显示通用说明；审计器不认证这些采集事实。任何一个前提不足或本地 rx/tx 时间域不一致时都不产生该测量；精确数值也不构成硬件准确度或绝对时钟精度结论。

选主部分有两条 Announce。候选 A priority1=100，B priority1=120，声明 selected=A；数据集比较之前，先检查 `bmca.snapshot`：

```json
{
  "epoch": 0,
  "window": "capture-0",
  "clock_domain": "slave-monotonic-0",
  "decision_time": {"seconds": "100", "nanos": 10000},
  "announce_validity_ns": 1000000000,
  "validity_source": "fixture-declared-observation-window",
  "validity_confirmed": true,
  "capture_window_confirmed": true
}
```

两条 Announce 的 capture_time 均为 100 s + 0 ns，决策时年龄为 10,000 ns，且处于相同 epoch/window/捕获时钟。只有这些前提和候选完整、eligibility_confirmed 声明成立后才进行 `BMCA.DIFFERENT_GM.priority1` 与 `BMCA.OBSERVED_DECISION` 检查。Announce 有效期是明确的输入政策，不代表本项目完成 foreign-master qualification 或完整端口状态算法。

JSON 报告每条 Finding 的 `evidence.referenced_frames` 展示实际头/body、零起始 PTP 字节偏移和观察元数据；`field_comparisons` 展示具体 source/domain/epoch/sequence/requester 左右值；`supplied_assumptions`、`observation_context`、`supplied_bmca_snapshot` 保留实际声明。`rule_reference` 标明来源与本地政策边界。`measurements` 另外展示 t1–t4 的帧和来源、correction 操作数、公式、中间量及精度限制；`coverage` 列出本次实际执行规则和状态，不能从总体 Pass 推断未执行功能也通过。

执行 `python3 scripts/verify_report_evidence.py` 可以用实际 CLI 重现报告核对。脚本用 Python struct/Fraction 独立读取 fixture，检查报告操作数、中间量、字节位置和真实输入回显，并构造缺 epoch、错 requester 两个反例；结果写入 [`research/report-evidence/verification.json`](../research/report-evidence/verification.json)，不把这些检查等同于真实捕获或 IEEE 认证。

已有可运行反例：将命令中的输入替换为 [`wrong-response-requester.json`](../fixtures/wrong-response-requester.json) 可定位请求方身份错配；[`missing-rx-time.json`](../fixtures/missing-rx-time.json) 返回证据不足；[`duplicate-delay-response.json`](../fixtures/duplicate-delay-response.json) 不产生测量；[`bmca-wrong-selection.json`](../fixtures/bmca-wrong-selection.json) 定位声明选错；[`bmca-error1.json`](../fixtures/bmca-error1.json) 对范围内无法解决的相等拓扑返回 Unsupported。删除 epoch 或缺少观察窗口时不会补成 0 并继续计算；跨观察分期、过期 Announce 和缺少快照确认也不能得到条件性的成功决策。
