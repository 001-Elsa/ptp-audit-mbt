# [ptp-audit](https://github.com/001-Elsa/ptp-audit-mbt.git)：PTP 同步证据核验与部署巡检

2026 MoonBit 黑客松 · 十月赛 | 工具库 / 开发者工具 | 版本 0.3.0

## 项目简介与实际需求

PTP 同步异常复盘需要同时解释报文能否关联、correction 如何影响偏差，以及测量是否来自设备声明选中的主时钟。ptp-audit 提供可复用的 MoonBit 库和离线 CLI，将这些分散证据连成可核对的报告，服务于网络部署验收、实验室软件栈验证和故障复现。

## 已实现的核心功能

- 解码 Sync、Follow_Up、Delay_Req、Delay_Resp、Announce 五类固定报文，校验身份、序号、显式观察分期、窗口及时钟域；缺失或冲突证据不冒充协议通过。
- 对 two-step / E2E 四帧交换使用精确整数计算 offset 与 mean delay，逐帧解释 correction 贡献；结合调用者给定的误差上界，输出条件区间与独立的同步门限结论。
- 核验有效 Announce 快照及限定 BMCA 数据集决策，将所选直接上游绑定到实际交换；巡检中区分上游端口与 grandmaster 变化，拒绝旧主污染和矛盾稳定区间。
- 提供 audit_json / commission_json 库接口与 check / commission 命令，输出实际字段、关联键、计算操作数、规则来源及未覆盖范围。

## 技术路线与本期新增贡献

以 MoonBit 分包实现 wire → observation / exchange → bmca → metrology / commissioning → evidence；Node.js 仅承担文件输入与执行适配。相较已保存的 0.3.0 基线，本期增加 correction 贡献账本、条件误差预算、选主与四帧来源绑定、跨检查点稳定性检查及 53 个独立巡检案例，并补齐文档、CI 和交付校核；已有基线不重复计为新增。

## 原创及参考关系与开源合规

项目为参考公开协议与开源实现、自主编写的 MoonBit 工具，不宣称发明 PTP 或通用区间算法。主体采用 Apache-2.0；LinuxPTP v4.4 为独立 C 对照来源，采用 GPL-2.0-or-later，未链接产品，源地址 github.com/richardcochran/linuxptp。MoonBit Core 与第三方范围见 THIRD_PARTY.md；授权不明确的外部抓包已退出交付。固定生态检索未确认完整同类组合，通用能力交集已披露。

## 完成度、验证与交付

已实现 6,004 行有效生产 MoonBit；native、JS、wasm、wasm-gc 每后端 455 项测试通过。169 个 CLI 案例及 7 个边界、1,012 项报告检查、935 项独立巡检检查通过。交付完整源码、README、示例、测试、CI 配置、来源说明和验证清单；源码 ZIP 解压后可复跑，后续优先维护反例回归与规则证据。

## 支持范围与演示

支持 IEEE 1588-2008 default multicast / E2E / two-step 限定子集。演示使用自构造数据；不认证采集真实性，不代表硬件精度实测或完整 IEEE 一致性，也不采集网卡或调整系统时钟。最小演示：bin/ptp-audit.mjs check fixtures/complete-audit.json --json。
