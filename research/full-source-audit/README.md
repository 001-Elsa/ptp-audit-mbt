# Mooncakes 当前索引的全量源码核查材料

本目录保存官方原始索引、固定版本逐包逐文件清单及可复验的扫描结果。第三方发布 ZIP 位于项目外部缓存；没有导入、编译、运行或解压第三方项目。

## 当前固定范围

2026-10-20 11:34:58（Asia/Shanghai）捕获的官方索引包含 **3,140 个唯一模块及其当前版本**，包括 yanked 条目，不包括每个模块全部历史版本。原始响应 SHA-256 为 `314de8d629c5ffd71a8cdbc893fc8a3b32af466a626cb5835d6ca03457fb646a`，对应 [index.json](index.json)、[原始响应](modules-response.raw.json)、[格式化索引](modules.json)。

扫描器 v4 对 **3,140/3,140 项均取得 `ok`**；`limited/unavailable/error` 均为 0，`unresolved` 为空。清单登记 284,094 个文本、6,301 个二进制成员，共 **290,395 个普通 ZIP 成员**；文本 3,587,979,940 字节、归档 1,297,116,902 字节、全部展开成员 4,544,106,611 字节。清单 SHA-256：`8dfe36f6ec05292a8eb639ab49be90cd5f28a6b6690fc91866ae648157262096`。

这次复用上一轮 3,138 项快照中的同一固定版本结果，再扫描本次索引的 2 个新增模块和 4 个升级版本；对两个同版本但 yanked 元数据变化的条目重新读取归档并更新结果。最后于 11:34:58 再次取得官方索引，模块数仍为 3,140，仅 `joanna/moonfeed` 升为 0.1.1，已另行扫描并重新执行全部完整性／补扫／join；见[最后一次索引变化](final-refresh-index-delta-2026-10-20.json)。全部旧结果只有在当前清单绑定后才计入范围。并非把历史检查数量直接相加。[本次索引变化](refresh-index-delta-2026-10-20.json) 保留实际比较记录；3,123 项历史快照的索引、清单、补扫与说明保存在 [history](history/2026-10-20-3123/README.md)，不作为当前结果。

## 已实际完成的独立复验

- [verification.json](verification.json) 重新读取全部 3,140 份归档及 290,395 个普通成员，检查 ZIP 大小、CRC、SHA-256、成员顺序与主清单绑定，结果通过。其 SHA-256 为 `199e7c594b46a68a0c4581b5a42cfecd41aec04d6eb0ac29468df8a01148eb53`。
- [NUL 源码检查](text-source-nul-review.json) 再次完整读取 212,839 个选中源码／README 成员，共 2,968,755,318 字节，发现 23 个含 NUL 成员。它们与已人工阅读的成员 path＋SHA-256 完全相同，复用其人工分类前重新核对全部记录的字节上下文；没有生成新人工判断。3 个是带 BOM 的 UTF-16，3 个 UTF-8 README 含短小的 UTF-16LE 形态重复标题尾部，17 个是含字面量／注释 NUL 的严格 UTF-8 源码。
- [audit_source_nul.py](audit_source_nul.py) 再独立重读全部选中成员，核对冻结清单、每个 NUL 偏移、完整计数和分类依据。[复验摘要](text-source-nul-review-recheck-summary.json) 及完整 recheck 均通过。刷新工具 [refresh_source_nul.py](refresh_source_nul.py) 遇到新的、无已读字节证据的 NUL 成员会失败，不能把未知编码自动认定为已审。
- [supplemental-binary-text.json](supplemental-binary-text.json) 再次完整读取及校验全部 6,301 个原二进制成员。112 个完整严格 UTF-8 文本、135 个含控制字符的严格 UTF-8 字节视图作补充关键词匹配，两类均无命中；6,054 个保留二进制分类。两份已固定 hash 的损坏／混合日志作可逆逐字节视图，没有新增命中。
- 同一补扫完整解码 64 个大文本候选，实际 2 条超长完整逻辑行重新匹配；其中保留 1 条早已人工复核的 `1588` 数值上下文命中，没有遗漏差异。20 个非 BOM UTF-16 的已登记 NUL 源码／文档另做完整行及 NUL 去除 ASCII 视图检查，没有新增命中。3 个 BOM UTF-16 成员已由主扫描器覆盖。补扫 SHA-256：`b0f0f34adb018e24a31228f6b6d78ba8c7a83c424a17ff7f94b19cb57316a295`。

以上记录证明固定范围的读取、编码处置和清单完整性。关键词用于定位语义复核候选：出现 `1588` 或 `follow-up` 不自动代表 PTP 实现，没有命中也不构成无语义相似性的证明。当前逐项语义、近邻和产品源码克隆证据见 [originality-completion](../originality-completion/README.md) 和 [当前功能对照](../../docs/non-overlap-current.md)。

## 复验

外部 ZIP 缓存默认位于 `~/.local/share/ptp-audit-tools/mooncakes-source-cache/`，不进入交付 ZIP。下列命令使用固定索引，不请求新的索引：

```sh
python3 research/full-source-audit/self_test_verifier.py
python3 research/full-source-audit/verify_manifest.py --workers 6
python3 research/full-source-audit/audit_source_nul.py --workers 6
python3 research/full-source-audit/supplemental_binary_text_scan.py --self-test
python3 research/full-source-audit/supplemental_binary_text_scan.py --workers 6
```

`verify_manifest.py` 不导入主扫描器，独立核对原始／格式化索引、扫描器和编码配置 hash、结果绑定、逐文件记录、全部 ZIP 及普通成员内容。NUL verifier 不覆盖冻结人工记录；默认输出单独 recheck。完整行超过 4 MiB 时补扫只允许一个 worker 积累该长行，最大实际 Python 行字符串为 12,633,061 字节，不包含临时副本和解释器开销。主扫描和补扫都明确记录下载、成员数、展开大小等安全上限；达到上限须显式记为有限覆盖，不可算作完成。

继续主扫描使用 `python3 scripts/audit_all_mooncakes_sources.py --workers 6 --retry-failed`。刷新官方索引增加 `--refresh-index`，但必须先保留旧快照，并在刷新后重新执行完整核验、NUL／二进制补扫和语义 join；不能只改模块数量。产品代码变化后还须重跑与本地源码 hash 绑定的克隆检查。公开下载使用正常 TLS 主机名和证书验证，[download-route.json](download-route.json) 记录官方发布端点的存储重定向证据。
