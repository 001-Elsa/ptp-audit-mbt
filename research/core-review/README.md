# 独立核心复核与真实反例

本轮只读检查 exchange 关联生命周期与测量门禁、BMCA snapshot 和严格 JSON 输入，使用 `node bin/ptp-audit.mjs check <case.json> --json` 实际执行构造输入。本目录没有修改产品代码；由根 agent 修复后，再独立重跑原输入。原始报告以 `.report.json` 保留，修复后报告以 `.after.report.json` 保存。

| 输入 | 修复前实际结果 | 修复后实际结果 | 判断 |
|---|---|---|---|
| `whitespace-event-clock-domain.json` | 纯空格 event clock domain 仍 Pass，1 个测量 | InsufficientEvidence / MEASUREMENT.EVIDENCE，0 个测量 | 已关闭；没有实际命名的时间域不能建立可比性 |
| `duplicate-exchange-claims.json` | 重复四帧声明触发 lifecycle EVICTED，但仍输出 2 个测量 | InsufficientEvidence / CLAIM.AMBIGUOUS，0 个测量 | 已关闭；生命周期与测量使用一致的唯一声明前提 |
| `whitespace-bmca-validity-source.json` | 纯空格有效期来源仍 Pass | InsufficientEvidence / BMCA.SNAPSHOT.EVIDENCE | 已关闭；独立合法 exchange 的 1 个测量保留，不把它当 BMCA 通过 |
| `bmca-only-invalid-unused-assumption.json` | BMCA-only 输入将 symmetric_path 写为字符串仍 Pass | INPUT.SCHEMA / Violation，0 个测量 | 已关闭；已提供的字段类型必须无条件检查 |
| `expired-sync-no-measurement.json` | 跨预算 Sync/FU 已正确阻止测量 | 仍为 InsufficientEvidence，0 个测量 | 正常负向对照 |

[`after-summary.json`](after-summary.json) 五项检查全部为 `check_pass: true`。[`negative-controls-summary.json`](negative-controls-summary.json) 另记录七项正常拒绝场景：未来 Announce、过期 Announce、跨 epoch 候选、不完整 capture window、Int64 预算溢出、null boolean、未知嵌套字段。它们均未返回总体 Pass；后四项不输出测量。前三项独立合法交换仍可输出自己的条件测量，不改变 BMCA 证据不足结论。

源文件摘要和复核边界见 [`manifest.json`](manifest.json)。这是一轮有具体反例的核心检查，不能当穷尽证明、规范全文审定或参赛认证。
