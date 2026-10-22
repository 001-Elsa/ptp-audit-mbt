# 发布与复现流程

更新：2026-10-22。用户已授权向指定 GitHub、GitLink 仓库按内容细分提交、分多批同步，并发布 Mooncakes。模块为 `001-Elsa/ptp-audit@0.3.0`，源码仓库名为 `ptp-audit-mbt`。个人信息和正式报名由本人在官方流程中提供。

复现工具链须同时满足 README 中的编译器与官方 Core 版本要求，不能只固定编译器而沿用不同的标准库。CI 在 Ubuntu 上单独检出并 bundle Core `eb321a18f7a33d37114546682a8d1cd6658afab8`。

## 验收与材料冻结

```sh
python3 scripts/validate_local.py --with-wire
# 未安装外部 TShark 时可去掉 --with-wire，其余门禁不变
scripts/moon-local build --target all
python3 scripts/verify_delivery.py --write
python3 scripts/build_application_pdf.py
python3 scripts/verify_delivery.py --pdf
python3 scripts/package_local.py
python3 scripts/package_submission.py
```

PDF 重建需要 reportlab、pypdf 和中文 TrueType 字体；普通库、CLI 与基础 CI 不依赖 PDF 作者工具。生成后渲染并检查一页布局、字体和可点击链接。源码包逐项核对文件与工作区字节，并在临时目录运行 native 测试及 CLI 正反例；正文或源码变化后须重建相应清单和材料包。

## GitHub 与 GitLink 分批同步

目标：<https://github.com/001-Elsa/ptp-audit-mbt> 与 <https://gitlink.org.cn/Hzhhhh/ptp-audit-mbt>。

保留 GitLink 原有初始化提交，在独立发布 checkout 中只导入已清理的当前文件，按基础配置、wire、观察关联、BMCA、计量、巡检、报告接口、CLI、回归样例、验证工具、架构文档、规范证据、生态审查、CI 及申报材料组织实质提交。每批推送后用远端 ref 验证。中间批次是完整交付的组成步骤；最终验收针对全部内容提交齐全的版本。

旧本地开发历史保留在原 checkout，不直接推送：其中曾包含授权不明确的外部抓包。公开历史必须检查所有可达对象，确认没有 `research/wireshark/ptpv2.pcap`；禁止 force push 覆盖已有远端历史，不制造空提交、倒填日期或把这次导入记录冒充此前逐日开发。

GitHub 使用 `main`，GitLink 保持原默认分支 `master`，二者最终 ref 指向同一提交。认证失败时保留实际失败结果和待推送 ref，不把另一平台成功算作本平台完成。GitHub Actions 根据最终提交的实际 run 判断，配置存在或本机命令通过均不能替代远端成功。

## Mooncakes 发布与消费验证

先执行 `moon whoami`，确认登录身份有 `001-Elsa` 命名空间权限；确认 `0.3.0` 未占用，完成最终归档检查，再执行 `python3 scripts/prepare_registry.py`。它从已验证的完整源码 ZIP 逐字节生成系统临时目录中的独立 staging（路径写入 `_build/publish/registry-staging-0.3.0.json`），仅省略 `research/`，保留所有库代码、接口、测试、样例、文档和 PDF。完整审查证据继续在两个 Git 仓库和参赛源码 ZIP 中交付。此划分用于避免 registry 对约 41 MB 完整证据包返回 HTTP 413。

staging 不放在受上层 `.gitignore` 排除的 `_build/` 内；生成器会实际打包，并检查文件集合、逐项哈希及体积，防止生成空 ZIP。在生成器输出的 staging 路径中执行 `scripts/moon-local package`、`scripts/moon-local check --target all --deny-warn`，确认精简 ZIP 小于上传限制，再执行 `scripts/moon-local publish`。不要依赖当前工具链的通用 `--dry-run` 选项作为不上传保证。账号凭据只存本机凭据位置，不能进入源码、日志或提交。

发布后读取官方 registry 元数据及 `https://download.mooncakes.io/user/001-Elsa/ptp-audit/0.3.0.zip`，核对名称、版本、repository、许可证，以及 ZIP 内全部文件与 `registry-staging-0.3.0.json` 中逐字节绑定的内容哈希；检查撤回抓包和 Git 对象未被带入。再在独立 MoonBit 消费项目执行 `moon add 001-Elsa/ptp-audit@0.3.0`，调用两个公开 JSON 入口并运行测试，证明消费端实际可下载、可编译和调用。

平台回执记录在 `research/publication/current.json`，随公开 Git 历史交付；该目录从不可变 registry ZIP 中排除，避免发布后回执反向改变包内容。回执不含密码、令牌、OAuth 授权码或浏览器会话数据。外层参赛 ZIP 的存在、源码公开和包发布均不表示官方已受理。

## 来源与赛事边界

源码包括当前生产模块、README、接口、测试、构造样例、文档、CI、许可证和可复核证据；不分发工具链、外部缓存、旧 Git 对象和授权不明确的抓包。TShark 的六帧 PCAP 由项目自构造，来源说明见 `THIRD_PARTY.md`。

十月赛公开官网记录见 `research/contest-2026-10-22/website-source.json`，报名与验收截止为 2026-10-31。飞书完整正文仍有登录限制；旧 6 月副本只作历史核对。身份、组队、群昵称、参赛次数和正式回执须在官方流程中确认，发布流程不替本人作法律承诺。
