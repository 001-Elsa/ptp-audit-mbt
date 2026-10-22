# 可复现验收与证据范围

## 0.3.0 本轮本地门禁

当前提交材料核验批次：2026-10-22。CI 统一执行完整本地 validator，另执行全目标 build、文档/材料校核和源码包干净解压验收。具体日志以 `research/validation-0.3.0/manifest.json` 为准；平台远端执行以 GitHub Actions 对应提交的实际运行结果为准，另记入 `research/publication/current.json`。

本轮新增 PTP correction 账本、条件误差预算、选主到四帧绑定及全 campaign 稳定性一致性检查后，已完成全目标 check、四后端测试、CLI fixture 回归、info 和 formatter 检查。下面逐项链接 0.3.0 本轮日志，不引用 0.2.0 的旧数字代替。

```sh
python3 scripts/validate_local.py --with-wire
scripts/moon-local build --target all
python3 scripts/verify_delivery.py --write
python3 scripts/verify_delivery.py --pdf
python3 scripts/package_local.py
```

第一条命令按顺序重建 fixture 和独立 C 向量，检查生成稳定性，运行全后端、CLI 和报告校核，最后执行 `moon info`、`moon fmt` 和格式检查；逐步命令、退出码、源码哈希及行数保存在 `research/validation-0.3.0/manifest.json`。未安装外部 TShark 的环境可去掉 `--with-wire`，其余本地门禁仍全部执行。第二条仅生成 ZIP，核对文件与工作区一致并在全新临时目录运行 native 测试和 CLI 正反例，不触发任何发布。

| 检查 | 本轮状态 | 本轮结果/证据 |
|---|---|---|
| 全目标静态检查 | 已通过 | `check --target all --deny-warn`；本轮 `check-all.log` |
| Native、JS、Wasm、Wasm-GC 测试 | 已通过 | 本轮在当前源码上直接执行 `scripts/moon-local test --target all --deny-warn`：每后端 455/455，共 1,820 次通过；当前日志和 manifest 均为这次运行的结果。 |
| CLI fixtures 与 I/O 边界 | 已通过 | 116 个原案例 + 7 边界；`research/validation-0.3.0/cli-fixtures.log` |
| 部署巡检与条件预算 | 已通过 | 53 个新增案例及原始独立反例，935 项 struct/Fraction/证据绑定检查；`research/validation-0.3.0/operational-evidence.log`、`research/commissioning/manifest.json` |
| `moon info` 与生成接口 | 已通过，新增接口符合预期 | `research/validation-0.3.0/info.log` |
| `moon fmt --check` | 已通过 | `research/validation-0.3.0/fmt-check.log` |
| fixture 再生成稳定性 | 已通过 | `regeneration.json`: `stable=true`, `changed=[]`；见 `research/validation-0.3.0/regeneration.json` |
| 报告 evidence 核对 | 已通过 | 1,012 项检查；`research/validation-0.3.0/report-evidence.log` |
| 独立 wire 解码 | 已通过 | 6 帧、5 类消息、130 字段；`research/validation-0.3.0/wire-reference.log` |
| 交付文档与申报来源 | 交付时必须匹配 | `verify_delivery.py` 核对版本、公开接口、schema、行数、测试/案例数、本地链接和文档/源码哈希；PDF 页数与正文哈希另行检查。 |

当前产品规模统计为 6,004 行有效 MoonBit 代码；统计排除 tests、research、build 输出、空行和整行注释。该数字是规模实测，不说明代码质量或参赛资格；本地章程 4–10k LOC 为参考范围，不通过填充代码追数。

旧 `research/validation/` 的 289/后端、60 fixture 等记录属于 0.2.0 历史验收；不能用它替代当前结果。当前 116 个 CLI 案例和 7 个边界已通过，详见 0.3.0 日志。

## 独立来源和验证边界

- **Wire 字段解码**：`python3 scripts/verify_wire_reference.py` 使用外部 TShark 4.6.9 双遍解码 `fixtures/complete-audit.json` 的六个 PTP payload；五类消息、130 项字段核对的保存结果见 `research/wire-reference/verification.json`。这些是项目构造样本，不是硬件抓包。检查只验证该批字节如何被外部 dissector 解读，不证明关联、BMCA、测量算法或完整 IEEE 一致性。
- **BMCA 数据集比较**：现有独立参考生成器会从 LinuxPTP C `dscmp/dscmp2` 产生向量。该来源是实现旁证，不等同 IEEE 规范；当前版本重新生成和测试状态须以本轮验收日志为准。
- **观察生命周期和快照**：新增白盒测试与 116 个 JSON fixture 分别覆盖显式观察上下文、窗口边界、deadline pending/expired、混合快照等代码路径；本轮四后端测试及 fixture 回归均通过。输入中声明的窗口完整性、时间戳来源和资格仍是调用者提供的证据，不会由离线 JSON 自动认证。
- **报告**：报告 schema 为 `ptp-audit-report/v2`；输入仍为 `ptp-audit/v1`。`evidence/` 中的生成代码和测试检查字段投影、关联证据、测量操作数、规则依据及覆盖范围。报告顶层 `expected`/`actual` 现在是带 `frame_ids`、完整帧字段、association keys、field comparisons、观察上下文和假设值的结构化对象；即使摘要仍为 `matching`/`mismatching`，也不会丢失本次实际值。报告对声明的结构忠实呈现，不验证声明来自真实设备。

## 规范依据状态

逐规则来源和限制见 [rule-traceability.md](rule-traceability.md)。已登记的官方公开材料、解释、LinuxPTP 和 TShark 交叉证据只对明确条目有效。由于完整、授权使用的 IEEE 1588-2008 正文未取得，纳秒边界、全部 control/保留行为、Clause 11 完整关联、same-GM 全部拓扑分支及 correction `tooBig` 解释冲突等仍有核对边界。不得把这些缺口写成完整标准条款已验证或 IEEE 认证。

实现规则清单包括 95 个规则标识；22 项规则测试已在四后端通过。另有 19 项 BMCA 教程分支测试已在四后端通过，它们核对的是 IEEE 802.1 托管的非规范教程流程图，不是完整标准正文。测试执行与依据范围见[规则与规范证据边界](normative-evidence.md)。

## 工具链

本机 MoonBit 工具链版本、macOS SDK 探针与 runtime 来源记录在 `research/toolchain-repair/manifest.json`。此前缺失的 native runtime C 源文件已从官方 Apple Silicon bundle 恢复；下载包 SHA-256 为 `563109ff02c6dc77fdc74acd0be423964ef678dfea4d9b948c19d245dc8b0e83`，只补齐 `~/.moon/lib`、`~/.moon/include` 和 `bin/internal` 中缺失文件，不替换现有编译器或项目源码。当前 `scripts/moon-local test --target native --deny-warn` 已在本轮验证中 455/455 通过，`moon check --target all --deny-warn` 也已通过。本轮工具链和门禁结果须以本轮日志为准；历史 manifest 只描述生成当时状态。

独立核心复审发现的空白事件时钟域、空白 BMCA 有效期来源、未使用假设的类型检查及重复交换声明四项问题均已修复，原始反例与修复后 CLI 复验保存在 `research/core-review/`；这五个新增 fixture 已纳入 116 个固定案例。重复/冲突的请求或响应声明通过 `CLAIM.AMBIGUOUS` 阻止产生重复测量。

新增 `metrology/` 有 14 项领域测试、`commissioning/` 有 11 项领域测试，已纳入全后端测试总数。原始规则族与新 METROLOGY/COMMISSION 规则合计 95 项：实现清单实际执行 169 个 CLI fixture，未由 CLI 触发的 typed API 规则仍通过 22 项专项测试补充；不得把规则数当作 IEEE 条款数。新增生成器/校验器与递归 fixture 哈希绑定已纳入验证及打包门禁。

本地 ZIP 核对由 `scripts/package_local.py` 完成：CRC、必要文件、全部打包内容与保存文件一致、原始第三方缓存排除，解包后 native 全测试及完整/缺失 epoch/混合 BMCA epoch，以及有效巡检/旧主拒绝/条件预算的 CLI 正反例。逐项结果和 ZIP SHA-256 保存在 ZIP 同目录的 `_build/publish/package-audit-0.3.0.json`，该外置清单避免把归档自身哈希递归写入归档。发布元数据已更新为模块 `001-Elsa/ptp-audit` 和仓库 `https://github.com/001-Elsa/ptp-audit-mbt`；远端 ref、registry 可下载性和 CI 状态另行核验，不能由 `moon package` 推断。

外部 Wireshark `ptpv2.pcap` 已从当前源码树撤回；归档验证器禁止其路径。现在分发的 PCAP 只有 `scripts/verify_wire_reference.py` 由项目 fixture 生成的 `complete-audit.pcap`。本地归档逻辑测试新增“与工作区字节一致的撤回样本也必须拒绝”反例，当前自测为 29 项；来源与分发边界见 `THIRD_PARTY.md`。
