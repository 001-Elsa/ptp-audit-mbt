# 可运行示例：选主变化后是否仍在使用旧 master 的交换

本例使用人工按网络字节序构造的 PTP payload，不是物理设备抓包。它把一个实际排障问题收窄为可验证的声明：设备记录已经选择 master B，但随后的完整 Sync／Follow_Up／Delay_Req／Delay_Resp 交换是否仍来自 master A？只看每个交换的算术正确性不足以回答这个问题；还需要同一次有效 Announce 决策及覆盖交换时段的选择稳定性记录。

在项目根目录运行，需要 Node.js 22 或以上及本地 MoonBit 工具链：

```sh
./bin/ptp-audit.mjs commission fixtures/commissioning/grandmaster-switch.json
./bin/ptp-audit.mjs commission fixtures/commissioning/grandmaster-switch.json --json
```

输出使用 `ptp-commission-report/v1`，退出码与 `check` 一致：0 为实际执行检查通过，1 为违规，2 为用法／文件／构建错误，3 为证据不足，4 为不支持范围。现有 `check <case.json> [--json]` 保持可用。

## 1. 先看符合声明的两个检查点

[`grandmaster-switch.json`](../fixtures/commissioning/grandmaster-switch.json) 使用 `ptp-commission/v1`。两个 step 各自嵌入一个完整 `ptp-audit/v1` 案例，不是分别提交几个来源不明的时间戳。

| 输入内容 | before-change | after-change |
|---|---|---|
| epoch／观察窗口 | 0／commission-window-0 | 1／commission-window-1 |
| 观察捕获时钟 | synthetic-slave-monotonic-0 | synthetic-slave-monotonic-0 |
| 接收端口 | 8899aabbccddeeff:1 | 8899aabbccddeeff:1 |
| 已声明并经 BMCA 核对的 selected | A | B |
| selected Announce sender | 0011223344556677:1 | 0011223344556678:1 |
| Announce 中的 grandmasterIdentity | 0011223344556677 | 0011223344556678 |
| 四帧的共同 master | 0011223344556677:1 | 0011223344556678:1 |
| 决策观察时刻 | 100 s + 500 ns | 101 s + 500 ns |
| 四帧捕获区间 | 100 s + [1300, 5250] ns | 101 s + [1300, 5250] ns |

每个 step 的 `selection_stability` 明确声明 `source`、`confirmed: true`、`until`。构造记录声称从决策到当前窗口末尾，同一 receiver/domain 的 selected sender 和它通告的 GM 都未更换；这不是从一条 Announce 自动推断的事实，也强于“端口状态不变”。每帧捕获时刻均落在决策之后、稳定性截止之前，也未超过选中 Announce 的有效期。

顶层 `capture_clock_continuity` 声明两个检查点使用连续的捕获时钟。具备这些前提后，报告中每个 `bindings[].accepted` 为 true；`transitions[0].classification` 为 `upstream_port_and_grandmaster_changed`。它只比较两个已接受观察区间的身份，不表示已经测出切换发生时刻、业务中断时间或同步恢复耗时。

报告结构保留复核路径：

- `steps[].case_report`：原单案例的完整协议、BMCA、测量和 metrology 报告。
- `steps[].selection`：selected candidate、Announce 帧号、upstream sender、receiver、GM、domain、epoch、window、决策和有效区间。
- `steps[].bindings`：四帧编号、是否接受、具体规则及 selected Announce／measurement／quartet 证据。
- `transitions[]`：只对相邻、全部成立的 step 作身份分类；前提缺失时分类为 null，不跳过失败检查点连接远处观察。
- `selection_conflicts[]`：对全部已通过检查点两两复核稳定性声明，只保留相同 receiver/domain/连续捕获时钟上、不同 sender 或 GM 的重叠声明。每项带双方 step、selection 证据及 `transition_inferred: false`，不作为非相邻切换结论。

这个基准 campaign 没有提供误差预算，所以 `status: Pass` 的同时，`operational_acceptance: unassessed`。报告不把“选主与交换证据一致”改写成“设备精度目标已验收”。

## 2. 复现“算术有效，但用错了 master”的反例

```sh
./bin/ptp-audit.mjs commission fixtures/commissioning/old-master-after-switch.json --json
```

[`old-master-after-switch.json`](../fixtures/commissioning/old-master-after-switch.json) 在 after-change 中仍声明并正确核对 selected=B，但四帧继续使用 A。这个交换内部的 source、sequence、requester 和 correction 都可以一致，原单案例仍可得到 offset=25.5 ns、mean delay=274.75 ns。新增绑定会产生 `COMMISSION.BINDING.IDENTITY`，总体为 Violation，after-change 的绑定拒绝接受。

使用者此时可以定位一个具体问题：从 Announce 决策到用于测量的上游来源之间存在矛盾。原始合法算术仍保存在 `case_report.measurements`，避免把“无法绑定到当前 selected”说成“四时间戳算术不成立”。报告没有把坏检查点之前之后的观察拼接为一次成功切换。

## 3. 区分边界时钟端口变化和 GM 变化

```sh
./bin/ptp-audit.mjs commission fixtures/commissioning/same-grandmaster-sender-switch.json --json
./bin/ptp-audit.mjs commission fixtures/commissioning/same-sender-new-grandmaster.json --json
./bin/ptp-audit.mjs commission fixtures/commissioning/stable-master.json --json
```

| 构造案例 | 预期身份分类 | 为什么需要单独区分 |
|---|---|---|
| same-grandmaster-sender-switch | `upstream_port_changed_same_grandmaster` | immediate sender 可以改变而 GM 不变；不能仅按 GM 字符串认定未换上游 |
| same-sender-new-grandmaster | `upstream_grandmaster_changed` | 相同 immediate sender 可以通告新的 GM；不能只按发送端口认定主时钟来源不变 |
| stable-master | `unchanged` | 两个检查点的 upstream sender 和 GM 都未变 |

这些分类表达的是观察到的 PTP 身份差别，不能单独证明设备执行了完整 BMCA 端口状态机。改变 master 后的 offset 仍归属于各自 case；工具不会跨不同 GM 做 offset 差并宣称测出绝对时钟跳变。

还可以运行 [`missing-selection-stability.json`](../fixtures/commissioning/missing-selection-stability.json) 和 [`missing-clock-continuity.json`](../fixtures/commissioning/missing-clock-continuity.json)。前者无法证明一次 BMCA 快照覆盖整个交换，后者无法建立相邻检查点的连续观察前提；结果保留为证据不足，不会填补假设后给出变化分类。

### 整批记录里的非相邻稳定性矛盾

```sh
./bin/ptp-audit.mjs commission fixtures/commissioning/nonadjacent-contradictory-selection.json --json
./bin/ptp-audit.mjs commission fixtures/commissioning/nonadjacent-selection-safe-control.json --json
```

[`nonadjacent-contradictory-selection.json`](../fixtures/commissioning/nonadjacent-contradictory-selection.json) 提交三个各自通过的检查点：

| 检查点 | selected／GM 来源 | 确认保持身份不变的闭区间 |
|---|---|---|
| long-A | A | [100 s + 500 ns, 104 s] |
| short-A | A | [101 s + 500 ns, 101 s + 100000 ns] |
| new-B | B | [102 s + 500 ns, 102 s + 100000 ns] |

各自的四帧和 Announce 都可以有效，相邻的 long-A→short-A 也只表现为身份未变，short-A→new-B 的两个短区间彼此分离。但 long-A 声称直到 104 s 都使用 A，new-B 又声称在这段时间内已经使用 B，这两项来源声明在同一 receiver/domain 和连续捕获时钟上相互矛盾。

整体检查会在 `selection_conflicts` 明确列出 long-A 与 new-B，产生 `COMMISSION.TRANSITION.CONTRADICTORY_STABILITY`，总体为 Violation，应用验收为 `evidence_not_accepted`。双方完整 selection 和 `transition_inferred: false` 一起输出。`transitions` 仍只有两个相邻关系，不额外生成 long-A→new-B 的切换；这是检查前提一致性，而不是越过中间检查点推断一次切换。

[`nonadjacent-selection-safe-control.json`](../fixtures/commissioning/nonadjacent-selection-safe-control.json) 把 long-A 的确认截止改为 100 s + 100000 ns，其他身份和交换保持相同。此时稳定区间不再矛盾，`selection_conflicts` 为空，总体为 Pass；相邻分类依次是 `unchanged` 和 `upstream_port_and_grandmaster_changed`。构造反例和对照共同检验：重复观察同一 A 不能覆盖它之前已经作出的长区间声明，真实无交叠的记录也不会被整体检查误拒绝。

## 4. 沿 correction 账本解释结果，并检查应用上限

```sh
./bin/ptp-audit.mjs check fixtures/commissioning/metrology-ledger-only.json --json
./bin/ptp-audit.mjs check fixtures/commissioning/metrology-within-limit.json --json
./bin/ptp-audit.mjs check fixtures/commissioning/metrology-outside-limit.json --json
./bin/ptp-audit.mjs check fixtures/commissioning/metrology-uncertain-boundary.json --json
```

这四例使用同一个四帧基准。`metrology[0].ledger` 显示未修正 offset=25 ns、mean delay=275 ns；Sync、Follow_Up、Delay_Resp 逐项贡献后得到 25.5 ns、274.75 ns。Delay_Req 的 correction 为 999999 scaled ns，并明确标为 `included: false`。

| 构造案例 | 外部声明预算 | `assessment`／应用判断 |
|---|---|---|
| ledger-only | 没有 error_budget | null；`assessment_state: not_assessed` |
| within-limit | 四时间戳、correction、不对称误差上界均为 0；offset 上限 50 ns | [25.5, 25.5] ns，`within_limit` |
| outside-limit | 同样的 0 误差构造预算；offset 上限 10 ns | [25.5, 25.5] ns，`outside_limit` |
| uncertain-boundary | 四个时间戳误差各不超过 1 ns，其余为 0；offset 上限 25.5 ns | [23.5, 27.5] ns，`indeterminate` |

表中的 0 误差预算只是构造向量，不能照抄为真实设备的校准证据。实际使用应填写可追溯的保守上界；缺少来源、假设或速率误差确认的案例不会得到条件精度结论。各合法预算案例的协议 status 都为 Pass，`outside_limit` 不会被误写成 IEEE 协议违规。误差模型、单位和边界等号规则见 [PTP 现场验收](../docs/commissioning.md)。

相同预算也可以放到 campaign 中逐 step 使用，并得到明确的总体应用状态：

```sh
./bin/ptp-audit.mjs commission fixtures/commissioning/commissioning-within-offset-budget.json --json
./bin/ptp-audit.mjs commission fixtures/commissioning/commissioning-outside-offset-budget.json --json
./bin/ptp-audit.mjs commission fixtures/commissioning/commissioning-indeterminate-offset-budget.json --json
```

三例均有完整的正确选择与交换绑定，所以协议 `status` 均为 Pass；`operational_acceptance` 分别是 `within_limit`、`outside_limit`、`indeterminate`。使用者因此能分别回答“这批证据是否相互一致”和“在给定外部误差界下是否达到了本次应用目标”，不会从一个总体绿色状态误读为所有精度要求已经验收。

## 5. 独立复算和反例回归

```sh
python3 scripts/build_commissioning_fixtures.py
python3 scripts/verify_commissioning.py
```

构造器使用 Python `struct` 写入网络字节序，未调用 MoonBit 编码器。独立核验器从 fixture 的实际字节读取身份、t1／t4 和 correction，结合明确的 t2／t3 元数据，用 Python `Fraction` 复算测量、逐项贡献和条件区间，再对照实际 CLI 输出；campaign 部分核对 selected 与 quartet 及前提反例。逐例输入摘要、实际状态和检查证据保存在 [`research/commissioning/manifest.json`](../research/commissioning/manifest.json)。

这是一条可复现的本地功能验证路径，既不冒充硬件实验，也不构成完整授权 IEEE 正文逐条核验或 Mooncakes 原创性认证。所有命令只操作本地文件和本地构建，不发布 Mooncakes、GitHub 或 GitLink。
