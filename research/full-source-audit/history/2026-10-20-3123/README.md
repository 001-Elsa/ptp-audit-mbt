> 历史原文快照：3,123 包源码清单。此文件不随当前实现更新；其中原相对链接按原目录解释。当前有效结果以主目录 README、manifest 和 hash 绑定报告为准。

# Mooncakes 当前索引的全量源码核查材料

这里保存官方模块索引、逐包逐文件清单和可恢复扫描的结果，不保存或执行第三方项目。

最终索引捕获于 `2026-10-19T15:47:59.723260+00:00`，包含 **3,123 个唯一模块及其当前版本**。v4 主扫描已完成，所有 3,123 项均为 `ok`，`limited/unavailable/error` 均为 0，`unresolved` 为空。共登记 **289,619 个文件成员**：主扫描识别文本 283,323 个、二进制 6,296 个；全部成员共 4,536,745,697 字节。归档下载总量为 1,295,137,802 字节。

独立核验于 `2026-10-19T16:06:34.587895+00:00` 完成，重新读取全部 3,123 份 ZIP 和全部 289,619 个成员，字节数、CRC、SHA-256 及清单绑定全部通过。最终主清单 SHA-256 为 `bc620c9c38eacf576e3cfa89a4a23451af76ea5d97a6c5ad2dcd621594768a35`；独立核验记录 SHA-256 为 `cce4f883fafbe2e34dd0cd8fb84eb99d7f303ebb17d429c365bc8a83b30af72a`。这些事实证明当前固定范围的读取和清单完整性；语义相似性需要另查人工复核与克隆筛查证据。

补扫于 `2026-10-19T16:09:43.445929+00:00` 完成，记录为 `supplemental-binary-text.json`（SHA-256：`5a4bbb3e3a11d3201760af8a33df0a41201de6f88b20c9462988ba435fa3721c`），所有既定检查均通过，限制和未解决项均为空：

- 全部 6,296 个原二进制成员再次完整读取及校验。其中 112 个实际为完整严格 UTF-8 文本，135 个为含控制字符的严格 UTF-8 字节视图，两类都进行了关键词扫描，均无命中。其余 6,049 个保留二进制分类。两份已逐一核实的 MoonReduce 混合/损坏日志另做可逆逐字节视图，亦无命中；没有把该视图称作原始字符编码。
- 全部 64 个超过 4 MiB 的主文本成员按登记编码完整解码，实际发现 2 条超长行。对完整行重新匹配，消除了主扫描滚动窗口在词边界及无界空白模式上的边界风险。仅复现 dockerlint 的 git-tree JSON 中原有的 1 条关键词记录，与主扫描的关键词类别没有差异，没有新增命中；另一条为 gorilla 数值向量，无命中。
- 对固定范围的 212,206 个常规源码/文档成员进行 NUL 字节检查，共 23 项得到人工分类：17 份源码中的字面量、3 份已被主扫描正确识别的 BOM UTF-16 文本，以及 3 份 README 中重复标题的混合尾段。20 份 UTF-8+NUL 成员另做完整核对和显式标注的 NUL-stripped ASCII 字节探针，均无命中；3 个 README 尾段登记原始 offset、hex 与可读标题，没有无依据地猜测任意二进制的编码。

- `modules.json`：本次捕获的官方索引，覆盖其列出的当前版本，包含 yanked 项；不等于每个模块的全部历史版本。
- `index.json`：官方 URL、捕获时刻、原始响应 SHA-256 和索引条目数。
- `manifest.json`：最近一次进度或最终汇总；只有 `final: true` 表示索引中的条目全部得到结果，仍需检查 `statuses` 和 `unresolved`，不能把下载失败或受限项算作已读源码。
- `results/<sha256(name + NUL + version)>.json`：包名、版本、官方 ZIP URL、ZIP SHA-256、每个文件的路径和 SHA-256、文本/二进制分类、命中规则及行号。所有限制、错误及不可取得情况单独记录。
- `run.log`、`final-run.log`：初轮及最终索引扫描的运行进度；最终的事实以逐包结果和 manifest 为准。
- `verify_manifest.py`：不导入扫描器的独立完整性核验器。读取固定索引和结果清单后，重新计算外部缓存中每份 ZIP 以及全部非目录成员的 SHA-256，检查原始/格式化索引、所有结果绑定、扫描器身份、编码覆盖配置与逐文件记录、派生命中清单和汇总计数。
- `verification.json`：独立核验成功后生成的记录，绑定最终 manifest 的 SHA-256；`verification_depth: archive_and_all_member_sha256` 表示已经重读全部 ZIP 成员，不能用仅核对归档 hash 的模式代称。
- `self_test_verifier.py`、`verifier-self-test.json`：用本地生成的两文件 ZIP 检查正常清单通过，并实际拒绝未完成清单、错误状态、陈旧结果绑定、错误扫描器、错误派生命中清单、修改配置后复用旧文件记录，以及被重新绑定的错误成员 hash。
- `supplemental_binary_text_scan.py`、`supplemental-binary-text.json`：在不改变主清单的前提下补扫原二进制中的完整 UTF-8 视图、明确核实的混合日志、超长完整行，以及 NUL 源码/文档；所有输入 hash 在运行前后均验证不变。补扫记录包含主清单和完整逐包结果的绑定，由后续语义复核记录再绑定该补扫结果。
- `text-source-nul-review.json`：固定 3,123 包范围的常规源码/文档 NUL 检查及逐文件人工分类；其 SHA-256 已进入补扫记录。
- `audit_source_nul.py`：使用外部缓存复验固定 NUL 人工分类的全部包、选中成员清单、逐文件 hash、NUL offset 及分类依据；它读取冻结分类，默认输出独立的 recheck 文件，不替代人工判断，也不覆盖冻结输入。
- `text-source-nul-review-recheck-summary.json`：NUL 复现脚本全量重核的短摘要，绑定复现脚本、临时 recheck、冻结人工 review、主清单和主扫描器的 SHA-256；记录 3,123 包、212,206 个选中成员、2,962,912,195 字节及 23 项人工 byte evidence 均通过。

原始 ZIP 缓存位于 `~/.local/share/ptp-audit-tools/mooncakes-source-cache/`，不进入产品目录或交付 ZIP。旧核查中的 56 个 ZIP 只有在 SHA-256 与旧清单一致时才复用；新下载使用官方发布存储 URL。扫描器只在内存中按流读取 ZIP 成员，不解压到磁盘、不 import、不构建、不运行第三方代码。

复现或继续扫描：

```sh
python3 scripts/audit_all_mooncakes_sources.py --workers 8
```

复查本轮失败项：

```sh
python3 scripts/audit_all_mooncakes_sources.py --workers 8 --retry-failed
```

如需重新捕获官方索引，增加 `--refresh-index`。这会形成新的核查范围；请保留原有索引和结果，以免把不同日期或不同版本的证据混写。

主脚本具有明确的下载、成员数和解压数据量安全上限，超过上限会记为 `limited` 或 `error`。大文本采用流扫描，不因超过 16 MiB 而默默跳过；异常超长单行在主扫描采用重叠窗口，独立补扫再对实际超长的完整行进行匹配。完整文件字节均参与 SHA-256。原二进制资源在主清单保留分类与 hash，其完整 UTF-8 内容视图由独立补扫另行检查，不把任意二进制强行当作文本。

独立重验不请求新索引，使用已固定的本次范围：

```sh
python3 research/full-source-audit/self_test_verifier.py
python3 research/full-source-audit/verify_manifest.py --workers 8
python3 research/full-source-audit/supplemental_binary_text_scan.py --self-test
python3 research/full-source-audit/supplemental_binary_text_scan.py --workers 4
python3 research/full-source-audit/audit_source_nul.py --workers 4
```

第二条命令要求扫描已完成且全部状态为 `ok`，并需要上述外部缓存。它检查的范围是最终索引中每个当前版本的所有普通 ZIP 成员；目录没有文件内容，未列出的历史版本不在此范围。交付 ZIP 保留清单和核验记录，第三方 ZIP 缓存仍保留在项目目录之外。

补扫需要已经固定的主清单及 NUL 人工分类记录。完整行超过 4 MiB 时只允许一个 worker 积累该长行，保留全部内容；本次最大的实际 Python 行字符串为 12,633,061 字节，此数字不包含列表、临时副本及解释器开销。补扫自测包含完整行词边界、超过 4,096 字符的空白以及跨原滚动窗口的 IEEE 数值上下文探针。

关键词命中仅用于定位需要语义复核的源码。`ptp` 可能只是 EtherType 映射，`1588` 可能只是测试数值，通用的窗口、超时、关联、日志结构也不自动意味着实现了 IEEE 1588。反过来，没有关键词命中也不是绝对无语义相似性的证明。需要结合源代码克隆筛查、具体功能逐项比较和人工复核记录解释结果。

`download-route.json` 保存官方发布端点返回的公开 CloudFront 重定向证据。下载器优先读取这个官方 CDN 的相同路径，失败则退回官方 origin；`dns-resolution.json` 保存系统解析得到的公开 IP，供并发 curl 复用，避免本机 DNS 饱和。两种路径均保留正常 TLS 主机名与证书验证。Range 续传只作用于项目目录之外的缓存。

初次索引最初仅把响应 hash 和解析后的 JSON 放入项目；随后从仍存在的原始 curl 临时文件找回完整 JSON 响应字节，核验 SHA-256 与最初记录完全一致，已保存为 `initial-modules-response.raw.json`，恢复过程记录在 `initial-index.json`。最终单次索引刷新另存 `modules-response.raw.json` 的原始 JSON 响应字节及 HTTP 头，并将其 hash、pretty JSON hash、唯一 `(name, version)` 数绑定到最终清单。最终清单还绑定本次 scanner 脚本和每个逐包结果文件的 SHA-256，便于在交付包中检查证据是否仍对应同一核查范围。

`initial-scan-manifest.json` 保留初轮扫描当时的历史汇总。逐包结果使用固定的包名/版本文件名，随后由 v4 全量重新扫描更新，因此该历史汇总里的旧结果 hash 不能用于校验当前结果文件。`results/` 还可能保留最终索引已经升级的旧版本记录；当前完整性证明只取最终 `manifest.json.result_bindings` 精确列出的集合，不用目录内所有 JSON 的数量代替核查范围。

`initial-encoding-findings.json` 保留原始编码问题；`encoding-overrides.json` 则只登记逐文件核实的编码或分类依据。Big5/GBK 示例按文件明确命名的编码严格解码，W3C HTML 按显式声明的 ISO-8859-1 解码。TOML 拒绝测试中故意损坏的 UTF-8 样本按完整原始字节人工检查后列为 binary fixture，保留路径和 hash，不把它谎称为有效 UTF-8 文本，也不跳过同一包的 MoonBit 源码。
