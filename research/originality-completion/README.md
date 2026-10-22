# 当前源码筛查、领域近邻与差异证据

当前外部固定范围是 2026-10-20 11:34:58（Asia/Shanghai）捕获的 **3,140 个当前模块版本**，完整原始索引、逐 ZIP／逐成员读取与独立复验见 [full-source-audit](../full-source-audit/README.md)。不是全部历史版本，不覆盖未发布项目。没有运行第三方代码。

## 当前语义复核

- [full-source-semantic-review.json](full-source-semantic-review.json) 将当前全部结果和人工 ledger 按 hash 连接。264 条强 PTP／IEEE／BMCA／correction／port identity 命中中，264 条有逐项实际阅读处置，涉及 24 包，待审为 0。普通 follow-up 词语另行保留，不能把这一结果称作所有源码逐行语义通读。
- [final-neighbor-review-coverage.json](final-neighbor-review-coverage.json) 绑定当前全部结果和两个邻域的人工记录：clock 76 包／232 条；request-response/deadline 32 包／58 条，当前保存的命中上下文均有处置，待审为 0。
- [supplemental-source-semantic-review.json](supplemental-source-semantic-review.json) 将原二进制、大文本完整行、NUL 字节视图的补扫和人工记录连接。保留 1 条已经阅读的数值上下文，新增待审为 0。它不擅自把普通二进制资源转成代码。
- [registry-3138-delta-semantic-review.json](registry-3138-delta-semantic-review.json) 和 [registry-3138-delta-neighbor-review.json](registry-3138-delta-neighbor-review.json) 保留前一轮只读增量审查原件。当前 join 重新选择本次固定索引中的版本，并不把这些历史文件的数量相加成新的覆盖率。

人工记录只有在 name、version、ZIP SHA、path、line、exact text 均一致时才能用于相同命中；编码／工具 metadata 的改变不能自动证明源代码没有改变。本轮新增 `temporal@0.1.2` 的年份 1588 已实际阅读日期测试上下文；`moonbit-community/uml@0.4.3` 的三条 clock 命中已实际阅读 timing-diagram 语法和测试上下文。这些是假阳性处置，真实功能交集仍然保留。

## 本轮领域增强的真实近邻

新增能力只实现 PTP 固定消息、操作数和证据前提。它没有扩展成通用 uncertainty／interval／事件窗口框架。具体已读源码证据见 [domain-enhancement-neighbor-review.json](domain-enhancement-neighbor-review.json)，当前产品对照见 [non-overlap-current.md](../../docs/non-overlap-current.md)。

领域报告绑定当前 manifest `8dfe36f6ec05292a8eb639ab49be90cd5f28a6b6690fc91866ae648157262096` 和最终本地增强源码，SHA-256 为 `b3e6743ee77b7e3b35fb399a59f046434bebfec6f8b444b287a005fb1109b122`。目标词发现覆盖当前 3,140 个版本／284,094 个文本／3,587,979,940 字节，251 包有 2,332 条类别＋文件＋行命中；12 个近邻另作逐段源码阅读。不能把全量关键词扫描说成全量逐行人工语义通读。

必须披露的交集包括：

- PTP 标准头／硬件寄存器：`hevienz/moonbit_libbpf`、`oboard/mocket`。
- 四时间戳测量、工业时钟或 timestamp fitting：NTP、MoonECAT、moon-kalman。
- 误差传播、保守区间、贡献表、计量阈值：`LunarUncertainty`、`moonbit_metrology`、`moonbitTolerance`、`measure`；任意精度有理数／区间也有现成库。
- 多字段键、完整输入前提、来源证据：`joinwitness`。
- 事件窗口、迟到／finality、确定性变化证据：`tideweave`。
- 精确 BigInt／scale：`json-schema`；结构化 source span／severity／JSON：`error-report`。

可支持的差异限于实际 PTP 组合：已接受四帧的具体身份与时间戳来源，Sync／Follow_Up／Delay_Resp correction 对 offset／mean-delay 的精确带符号贡献、Delay_Req 不重复扣除，调用者有来源的 PTP 上界形成条件 offset 区间，以及有效 Announce／BMCA 选择的直接 sender 到实际 quartet 的绑定和单独 GM 变化解释。数学公式与标准 BMCA 不是独占发明。

## 源码克隆筛查

本轮功能完成后冻结 **18 个生产 MoonBit 文件／33,149 个 token**，对固定的 **3,140 包**完整重跑。外部源码为 93,828 个生产文件、137,529 个全部 MoonBit 文件和 238,968,538 个 token；4,966 个生成文件、43,701 个外部测试文件全部纳入。包覆盖恰好一次，合并后本地 source、逐包 metadata 和全部归档 hash 均验证不变。未解决包、有限清单和显式排除均为 0。

[40/5 报告](full-source-clone-screen-40.json) 的 SHA-256 为 `de049544271b313b9703d78197ab3bf3e4d370dbfba0bd2abf33ba9c18f5b8bb`，得到 4 个候选，已全部从当前本地源码和固定 ZIP 再次实际阅读；[人工处置](full-source-clone-human-review.json) 记录 ZIP／成员／本地 SHA 和所读上下文。三项是 JSON required-field getter（46 token），一项是两字段字典序比较器（74 token，外部为音频 Duration、本地为 PTP PortIdentity）。它们是实际通用文本交集。新增 metrology／commissioning 文件没有达到门槛的候选，但此事实不证明没有语义相似。

[80/8 报告](full-source-clone-screen-80.json) 由同一组最大匹配严格派生，候选为 0，SHA-256 为 `6deb8fe6819a43b8c24c9df6ca587d2fc8fdf9395a0d1d9e30956af2475c1f83`。打包器的完整源码与 originality 两个证据门禁均已针对当前生产源码实际通过。旧 3,123 包／15 生产文件结果保存在 [history](history/2026-10-20-pre-enhancement/README.md)，不作为当前增强代码的证据。

检测命令为：

```sh
python3 scripts/verify_source_originality.py --self-test
python3 scripts/run_source_originality_full.py --workers 6
```

检测器对本地生产 MoonBit 代码和所有外部 MoonBit 源码执行两类有界比较：去掉注释／空白、保留标识符／字面量／运算符的精确 token 片段；完整 `///|` 块的一致双射标识符替换。40 token／5 行是候选门槛；80 token／8 行从同组最大匹配作严格子集派生。所有种子都碰撞核对并最大延伸。外部测试和明确生成代码都纳入；本地测试、JS／Python／shell、生成接口和低于门槛的片段不在这份生产 MoonBit 对比范围。

源代码按严格 UTF-8（可带 BOM）或 BOM 明示的 UTF-16／32 解码；无效编码／大小限制必须逐项记录，不能计成已扫描。32 MiB 单源文件上限是显式方法边界。分片合并后核验本地 source SHA 未变化、全部包恰好覆盖一次、结果 metadata 和全部 ZIP hash 一致。输出和人工候选处置都必须与同一清单及本地源码绑定。

这些检查能发现并处置特定阈值下的词法交集，不能证明语义改写不存在、任何层面绝对零类似、永久独有或赛事通过。当前已确认的交集不得因低阈值候选是通用代码而被隐去。
