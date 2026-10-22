# 规则与规范证据边界

当前实现清单包含 95 个规则标识，逐项登记了检查条件、源码位置、依据类别、CLI 触发证据或独立向量，以及尚未核验的边界。规则标识不等同于 IEEE 条款数，也不意味着每个分支都已穷举。

规则测试共 22 项，在 native、JS、Wasm 和 Wasm-GC 四个后端均通过（88 次执行）。另外，BMCA 教程分支测试共 19 项、每后端均通过，合计 76 次执行、100 次数据集比较。该测试根据 IEEE 802.1 托管的 Garner 教程绘制的比较流程图核对实现；它是独立的非规范参考，不是完整 IEEE 正文。详细证据见 [rule inventory](../research/normative-completion/rule-inventory.md)、[rule test coverage](../research/normative-completion/test-coverage.json) 和 [BMCA tutorial review](../research/normative-completion/bmca-tutorial-branch-review.md)。

完整授权 IEEE 1588-2008 / IEC 61588:2009 正文尚未取得。公开解释、官方预览、教程、LinuxPTP 实现和 TShark 解码各自只支持记录中明确限定的事项；它们不能合并成完整标准认证。实际访问路线及结果见[来源访问记录](../research/normative-completion/source-access.md)。

因此，95 个规则标识和已通过的测试只能说明登记范围内的实现与具体断言得到检查，不能证明完整 IEEE 一致性、穷尽分支覆盖或正式认证。报告中的 Pass 仍只适用于报告列出的已执行规则和输入证据。

新增 METROLOGY 与 COMMISSION 的 16 项规则全部属于项目 PTP 代数解释或输入证据政策，未扩充 IEEE 子集。`metrology/` 的 14 项和 `commissioning/` 的 11 项测试均纳入本轮全后端运行；另有新增 53 个部署/预算 fixture，以及对独立审查原始非相邻矛盾反例的 CLI 复验，见 `research/commissioning/manifest.json`。精确公式、条件门限和稳定区间语义见 [部署巡检说明](commissioning.md)。
