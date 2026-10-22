"""Render audit evidence and manually reviewed functional-neighbor findings."""
import json,hashlib
from pathlib import Path
from datetime import datetime,timezone
root=Path('research/2026-10-19');mods=json.load(open(root/'modules.json'));rows=json.load(open(root/'page-audit.json'));summary=json.load(open(root/'summary.json'));review=json.load(open(root/'reviewed-neighbors.json'))
missing=[r for r in rows if r['status']!='ok']
manifest={'snapshot_date':'2026-10-19','report_generated_at':datetime.now(timezone.utc).isoformat(),'module_index_url':'https://mooncakes.io/api-new/v0/modules','module_index_sha256':hashlib.sha256((root/'modules.json').read_bytes()).hexdigest(),'total':len(mods),'active':sum(not m.get('yanked',False) for m in mods),'yanked':sum(bool(m.get('yanked')) for m in mods),'empty_description':sum(not (m.get('description') or '').strip() for m in mods),'summary':summary,'reviewed_neighbors':len(review),'scope':'All snapshot module metadata and current-version public root docs; selected supplemental docs. Not all subpackages, source files or historical versions.','project_sources':{str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in [Path('moon.mod'),Path('moon.pkg'),Path('moonbit-ptp.mbt'),Path('moonbit-ptp_wbtest.mbt'),Path('cmd/main/main.mbt')] if p.exists()}}
json.dump(manifest,open(root/'manifest.json','w'),ensure_ascii=False,indent=2)
s=f'''# Mooncakes 全量筛查与功能重合报告

检查日期：2026-10-19（Asia/Shanghai）。对象：本工作区 `moonbit-ptp`；本地源码哈希见 [manifest.json](../research/2026-10-19/manifest.json)。

## 结论与此前结论的修正

**存在部分功能相似和重合。按用户要求的“任何类似、重合都不可接受”门槛，当前项目不能标记为可安全提交。** 此前根据 3,041 个模块和少量关键词给出的非重合结论撤回。

本次没有找到公开根文档能够证实的同功能完整 IEEE 1588 PTP/BMCA 实现。扩展标准关键词唯一命中 PROFINET 的 `snmp_feature_ieee_8021as_mib_optional`，只说明有可选 MIB 相关接口，不能据此认定实现了 gPTP。未找到直接 PTP 实现，不等于不存在部分功能相似，也不等于全站全部源码已被证明无重合。

已经证实的交集包括物理时间同步测量目标、工业分布式时钟的漂移/传播延迟处理、网络延迟/抖动/丢包仿真、确定性实验、时间表示和运算。协议不同、项目名称不同、应用领域不同，均不足以排除这些交集。

功能相似不是源码复制证据；本次未开展全生态源码克隆检测。是否违反赛事的正式原创性规则，应按完整官方章程和评审口径认定，本报告不虚构“官方已判失败”或“已通过”。

## 全量范围与可追溯性

| 检查项 | 本次结果 |
|---|---|
| 官方完整模块索引 | {len(mods):,} 条，包含 {manifest['active']:,} 个未撤回模块与 {manifest['yanked']} 个 yanked 模块；未主动过滤撤回包 |
| 简介为空的模块 | {manifest['empty_description']} 个，也逐包尝试读取文档 |
| 公开根文档有效读取并筛查 | {summary['ok']:,} 个 |
| HTTP/网络等读取失败 | {summary['failed']} 个 |
| 页面返回但文档资源不可用 | {summary.get('unavailable',0)} 个；不得视为无风险 |
| 根文档自动命中复核 | 46 个模块，全部附判定说明；自动命中不等于功能重复 |
| 人工重点对照 | {len(review)} 个相近/相关模块，见下表和逐项摘录 |
| 补充深入读取 | 13 个页面/设计文档：网络仿真设计/API、分布式仿真 API/架构、工业虚拟时钟子包等 |

索引入口：[官方模块列表 API](https://mooncakes.io/api-new/v0/modules)。使用索引记录的版本读取 `https://mooncakes.io/docs/<owner>/<module>@<version>`；首次重点读取的未固定版本页面均对应同一索引版本。文档提取正文时排除 script/style，并为正文生成 SHA-256。完整索引、逐包结果和正文快照均已保留。

本次对全部索引条目进行名称、简介、关键词和公开根文档的自动筛查，对 46 个根文档自动命中模块逐项复核，并整理 25 个重点相近项目的语义对照。**不是逐行人工审阅 3,113 个项目全部源码**。未穷举全部嵌套包、仓库分支、历史版本、尚未发布的项目，也不覆盖检查结束后的新增包。未命中只表示在当前可读内容和查询规则下未检出，不表示该模块已获“无任何相似”证明。

直接方向检索包含 PTP、1588、BMCA、grandmaster、802.1AS/gPTP，以及下划线/无点号等写法。邻近方向扩展到 NTP/SNTP、时钟/时间同步、servo、分布式时钟、逻辑/因果时钟、网络/分布式/离散事件仿真、选主、时间表示和控制。完整正则见 [扫描脚本](../scripts/audit_mooncakes.py)；扩展元数据候选见 [expanded-candidates.json](../research/2026-10-19/expanded-candidates.json)。

## 重点模块逐项对照

下列风险标签用于本项目选题审查，不是赛事官方等级。“邻近”不代表已确认同功能重复，但在用户零相似门槛下也不能忽略。

| Mooncakes 项目及版本 | 已核实的现有能力 | 本地对应部分 | 判定和区别 |
|---|---|---|---|
'''
for x in review:
 s+=f"| [{x['name']}@{x['version']}]({x['url']}) | {x['features']} | `{x['local']}` | **{x['risk']}**。{x['boundary']} |\n"
s+='''
逐项正文摘录与来源路径见 [reviewed-neighbors.json](../research/2026-10-19/reviewed-neighbors.json)。对普通 HTTP 客户端的注入 Clock、Raft 的 term 逻辑计数、神经网络的 network simulator、reservoir 等子串命中进行了排除性复核；这些命中不能被当作 PTP 项目重复。完整自动命中保留在逐包结果中，不能把自动命中数等同于相似项目数。

## 当前代码为何不能支撑“零重合”的申报

- `Timestamp`（`moonbit-ptp.mbt:3` 起）提供秒/纳秒表示、归一化和加减，时间运算已有生态包。
- `Clock::apply_sync`（484 行起）和 `simulate`（573 行起）做偏移调整及简化 PI 控制；NTP 和 EtherCAT DC 已覆盖时间同步测量或漂移处理方向。不能把算法和协议的差异写成没有功能相似。
- `NetworkModel`（510 行起）明确包含前向/反向延迟、抖动、丢包，正好与网络及无线链路仿真包的能力部分相交。
- `select_grandmaster`（417 行起）是质量元组排序；当前发现的 Raft/租约选举与它不同，没有证据证明 BMCA 源码或算法实现重复。但选主这一抽象概念本身并非独有。
- 当前自定义紧凑消息编解码不是完整 IEEE 1588 标准报文。`encode_standard_header`（673 行起）只编码公共头；缺少完整消息体、标准解码、真实 t1/t2/t3/t4 交换和互操作验证。不能把尚未完成的标准能力算作已经交付的差异化成果。

## 未能读取的文档

'''
if missing:
 for x in missing:s+=f"- [{x['name']}]({x['url']})：{x['status']}。{x.get('error','站点显示 Docs unavailable / Documentation assets could not be loaded。')}\n"
else:s+='无。\n'
s+='''
重复访问记录见 [unavailable-retries.json](../research/2026-10-19/unavailable-retries.json)。其中 `wit-wasi-clocks` 与时钟基础能力有关，尤其不能把文档缺失视为已排除相似性。

## 后续处理建议与提交门禁

1. 当前版本先按“相似性风险未解决”处理，撤回 README 和合规材料中已满足非重合要求的表达；本次已同步修正文档。
2. 通用时间类型、通用仿真和基本网络损伤模型不能再作为生态空白或主要创新点。改名、换术语、增加 CLI/测试都不能消除已有功能交集。
3. 若继续 PTP 方向，应先对完整标准报文、correctionField 定点运算、two-step 与乱序/丢包关联、特定 profile 的 BMCA/数据集、真实报文及互操作等具体交付物做更深入查重，再决定是否收窄范围并实现。这里只是待研究的差异化方向，**尚未证明零相似，也没有在本次擅自改写项目**。
4. 若官方将任何基础能力交集都算不合格，需要先明确可以验收的判定粒度；所有协议库都会使用时间、编码或状态机，不能把这种宽泛条件包装成可由关键词扫描保证的事实。
5. 在满足可核实的差异化边界后，提交前仍需刷新全量索引、修复文档访问缺口并按完整章程核对。当前不能出具“肯定不会因相似而失败”的保证。

## 复核入口

- [完整模块索引](../research/2026-10-19/modules.json)
- [逐包读取状态、版本、哈希与命中摘录](../research/2026-10-19/page-audit.json)
- [全部自动命中的复核结论](../research/2026-10-19/screening-review.json)
- [统计摘要](../research/2026-10-19/summary.json)
- [重点项目语义对照与摘录](../research/2026-10-19/reviewed-neighbors.json)
- [补充设计/API 文档读取记录](../research/2026-10-19/supplemental-audit.json)
- [来源、数量和本地源码哈希](../research/2026-10-19/manifest.json)

在当前目录运行 `python3 scripts/audit_mooncakes.py` 可对本次保存的索引和正文快照重新筛查，并重试缺失的页面；脚本复用缓存，**不会自动刷新索引或已缓存页面**。新的提交日复查须另存当日官方索引和文档，不能把缓存重放冒充实时查重。运行 `python3 scripts/build_mooncakes_review.py` 生成重点摘录，`python3 scripts/review_mooncakes_hits.py` 生成命中复核记录，`python3 scripts/write_mooncakes_report.py` 生成本报告；语义判断需要人工维护。
'''
Path('docs/non-overlap.md').write_text(s)
print(json.dumps({k:manifest[k] for k in ['total','active','yanked','empty_description','reviewed_neighbors']},ensure_ascii=False));print(summary)
