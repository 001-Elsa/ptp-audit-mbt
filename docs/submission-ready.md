# 十月赛本地提交材料说明

更新：2026-10-22；项目版本：0.3.0。

本页是当前交付入口。此前 `charter-audit-2026-10-21.md` 是整改前的核对快照；当前修正、赛事依据、验证状态以本页和 `charter-compliance.md` 为准。用户已新授权 GitHub/GitLink 按内容分批同步及 Mooncakes 发布，远端状态另见 `research/publication/current.json`；正式报名仍由本人办理。

## 赛事依据

本次重新读取 [2026 MoonBit 黑客松官网](https://moonbitlang.github.io/Hackathon2026/) 的公开页面及其页面脚本。官网当前明确：十月赛报名与验收截止为 **2026-10-31**；每队不超过 3 人；十月最多提交 3 次，实际报名时间按通过审核前最后一次有效提交/修改计算；已有项目须有本期实质新增工作；提交一页项目说明、代码、README、测试和可复现演示；选手须进群并将昵称设为 GitHub ID。这些是官网可读信息，不是 6 月旧章程副本的推断。

官网直接链接到用户给出的飞书章程 `Dx4Bwd6D1i3GfHkajQCcF7SznEd`；本次请求仍跳转登录页，未取得全文。公开官网与 6 月副本在个人/组队、时间、推荐奖励等方面存在版本差异，不能把旧副本的个人参赛限制或 7 月赛程当成本期硬性规则。完整旧副本逐条核对保留作历史材料；当前无法确认其全部条款与在线飞书一致。新官网来源、关键原文及哈希见 `research/contest-2026-10-22/website-source.json`。

## 材料与用途

| 文件 | 用途 |
|---|---|
| `output/pdf/ptp-audit-项目申报书.pdf` | 正式一页项目说明，中文 A4，嵌入字体；包含需求、功能、路线、本期贡献、来源、验证及边界。 |
| `PROJECT_APPLICATION.md` | 申报书可编辑正文；PDF 由此生成，正文不另行手抄。 |
| `_build/publish/001-Elsa-ptp-audit-0.3.0.zip` | 完整本地源码交付，包含接口、文档、测试、构造数据、CI 配置、申报材料和来源/验收证据。 |
| `_build/publish/package-audit-0.3.0.json` | 源码包 CRC、内容哈希和全新目录解压运行的实际结果。 |
| `output/submission/ptp-audit-0.3.0-参赛材料.zip` | 便于一次交付的外层材料包：一页 PDF、完整源码 ZIP、申报正文、提交说明、源码包验收结果及校验清单。不包含 `.git` 或账号资料。 |

按用户要求，PDF 不填写姓名、联系方式、队伍人数，也不放“待填写”等占位符；标题保留用户添加的 GitHub 源码链接，并生成为可点击的 PDF 链接。个人身份和参赛者信息由官方报名表承载；本地材料不替本人作报名、唯一性、宣传授权或税务承诺。平台地址与包名已写入 README 和模块元数据，实际内容与版本按发布流程独立核验。

## 已落实的整改

1. **申报材料**：完成独立的六节正文和一页 PDF；说明是参考公开协议/实现、自主编写的工具，明确本期新增与已有基线的区别，不将全部旧代码重复计算为本期贡献。
2. **第三方数据**：外部 `research/wireshark/ptpv2.pcap` 已移出当前源码和交付树，仅留来源、哈希及历史观察；当前归档验证器显式禁止该路径。所有过关 fixture 和独立 TShark PCAP 均由项目生成器自构造。旧 Git 对象不进入源码 ZIP，也不凭历史存在声称已获再分发授权。
3. **CI**：统一调用 `validate_local.py`，覆盖原有及新增的 53 个巡检案例、935 项独立检查、规则证据与打包自测；另有显式全目标 build、文档/材料校核及干净解包验收。配置与本机运行分别表述，未声称远端 Actions 已运行。
4. **文档同步**：`verify_delivery.py` 核对版本、接口/命令、输入输出 schema、实测行数、fixture/测试数量、Markdown 本地链接、许可证和撤回样本；生成的交付快照记录文档与代码 hash。代码、测试或文档变化后须重新核对并打包，不能沿用旧成功清单。
5. **源码冻结**：交付 ZIP 按当前已保存文件制作，包含本期新增 metrology/commissioning 实现及其文档/测试，不只取旧 Git HEAD；本地提交与更新日志用于记录实质贡献，不添加空提交凑次数。

registry 包通过 `scripts/prepare_registry.py` 从已验证源码 ZIP 逐字节派生，仅省略 `research/`，用于控制包体；完整审查证据由源码 ZIP 和两站仓库承载，完整验收须在这些源码入口执行。registry 下载后的文件清单与 staging 清单逐项核对。

## 本期贡献怎样复核

`CHANGELOG.md` 顶部区分当前增强和原 0.3.0 基线。可从 `metrology/` 的逐帧 correction 贡献与条件区间，追到 `commissioning/` 的有效选主绑定、相邻身份变化及全 campaign 稳定区间冲突检查。新增 `fixtures/commissioning/manifest.json` 记录 53 个案例；`scripts/verify_commissioning.py` 以 Python struct/Fraction 独立读取报文字节与预期数值。新增能力是具体 PTP 证据链工程，不将通用区间算法、时序窗口或报告格式宣称独有。

原始 0.3.0 基线的 4,253 行、430 项测试属于历史数据；当前生产代码为 6,004 行、四后端每后端 455 项测试，参见 `docs/validation.md`。固定 2026-10-20 生态快照已绑定当前 18 个生产 MoonBit 文件，未确认完整同类 PTP 组合；该证据不能证明任意零相似或替代赛事裁定。本轮没有通过简单改名、拆项目或伪造提交避开原创性要求。

## 复现和生成

需要 MoonBit、Node.js 22+、Python 3.9+ 和系统 C 编译器；Node.js 必须可从 PATH 找到。PDF 重建额外需要 `reportlab`、`pypdf` 和可嵌入的中文 TrueType 字体；这些不是运行 MoonBit 库的依赖。

```sh
python3 scripts/validate_local.py
scripts/moon-local build --target all
python3 scripts/verify_delivery.py --write
# 若已有外部 TShark，可在 validate_local.py 增加 --with-wire
python3 scripts/build_application_pdf.py
# 非 macOS 可提供中文 TrueType 字体：--font /path/to/cjk.ttf
python3 scripts/verify_delivery.py --pdf
python3 scripts/package_local.py
python3 scripts/package_submission.py
```

`--write` 更新文档/代码的交付快照；普通运行重新核验实际文件与快照，拒绝使用落后的文档证据。PDF 生成后还须渲染并目视检查一页布局；正文或 PDF 变化需重新执行校核。外层材料包仅在源码 ZIP、当前文件及 PDF 来源全部匹配后制作。

## 声明与后续事项

支持范围是 IEEE 1588-2008 default multicast/E2E/two-step 的明确子集。Pass 只覆盖报告实际执行规则；采集真实性、调用者预算、稳定性与完整性声明不能由离线 JSON 自动认证。硬件精度实测、完整 IEEE 认证、完整 BMCA 端口状态机及网卡采集不在本次声明能力内，章程也未对所有项目普遍要求这些能力。

个人信息、队伍/群昵称、实际申报次数、正式回执、官方最新完整章程及入围后的答辩由本人按官方通知确认；本地文件不能代为完成。平台交付已纳入此次执行，按内容分批保留提交并逐站核对，不将平台发布成功表述为官方已受理或全部赛事流程通过。
