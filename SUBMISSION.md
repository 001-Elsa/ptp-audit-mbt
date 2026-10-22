# ptp-audit 0.3.0 参赛材料

本材料面向 2026 MoonBit 黑客松十月赛，项目为 PTP 同步证据核验与部署巡检库及 CLI。

- `项目申报书.pdf`：一页中文项目说明，优先用作项目申报附件。
- `PROJECT_APPLICATION.md`：申报书的可编辑正文。
- `001-Elsa-ptp-audit-0.3.0.zip`：完整源码、文档、构造样例、测试、CI 配置和许可证/来源/验证证据。
- `package-audit-0.3.0.json`：源码归档校核与全新目录解压运行结果。
- `SHA256SUMS.txt`：材料包内文件的校验值，不对校验清单自身递归计算。

先解压源码 ZIP，再按 README 运行：

```sh
bin/ptp-audit.mjs check fixtures/complete-audit.json --json
bin/ptp-audit.mjs commission fixtures/commissioning/grandmaster-switch.json --json
python3 scripts/validate_local.py
```

运行前准备 MoonBit（已验证 moonc v0.10.15+943464bfa）、Node.js 22+、Python 3.9+ 及 C 编译器。所有演示均为自构造数据；不代表硬件精度实测或完整 IEEE 一致性认证。源码内 `docs/submission-ready.md` 说明支持范围、来源及复现方式。

个人身份和联系方式按用户要求不写入本 PDF，在官方报名表中另行提供。源码平台使用 GitHub `001-Elsa/ptp-audit-mbt` 与 GitLink `Hzhhhh/ptp-audit-mbt`；Mooncakes 模块为 `001-Elsa/ptp-audit@0.3.0`。平台实际结果见仓库中的 `research/publication/current.json`，正式报名由本人另行办理，材料包的存在不表示赛事已受理。官网当前十月报名与验收截止为 2026-10-31，最终执行以官方通知和章程为准。
