# 独立 wire 交叉验证

`fixtures/complete-audit.json` 中六个实际 PTP payload 已由真实的外部 **TShark 4.6.9** 双遍解码。五种报文类型均覆盖；130 项字段检查全部通过，没有 malformed 报文。机器可读结果见 [verification.json](../research/wire-reference/verification.json)，原始解码见 [tshark-complete-audit.json](../research/wire-reference/tshark-complete-audit.json)。

这是文件样本的独立协议解码验证。输入是项目构造的完整交换样本，封装为 Ethernet PCAP 后交给 TShark；没有将它描述为网卡硬件实测或完整 IEEE 一致性认证。关联算法、BMCA 算法和 offset/delay 计算分别有自己的参考向量与测试，不借用这次 wire 检查声称通过。

| 实际 fixture 帧 | 独立解码类型 | PTP 长度 | 关键核对项 |
|---|---|---|---|
| 1 | Sync | 44 | 双步标志、source、seq=7、100s/0ns、correction=-0.5ns |
| 2 | Follow_Up | 44 | 相同 source/seq、100s/1000ns、correction=0.25ns |
| 3 | Delay_Req | 44 | slave source、seq=31、100s/5000ns、correction=999999/65536ns |
| 4 | Delay_Resp | 54 | master source、seq=31、requester、100s/5250ns、correction=0.75ns |
| 5 | Announce | 64 | UTC offset=37、priority1=100、class=248、accuracy=0x22、variance=17185、priority2=128、GM、steps=0、timeSource=0xa0 |
| 6 | Announce | 64 | priority1=120 和另一个 GM，以及其余完整字段 |

各帧还核对 version=2、minorVersion=0、domain=0、两处兼容 2008 的保留/组织字段为 0、source port、control、logMessageInterval 及 timestamp。TShark 的 `correction.ns` 为带符号整数向下取整部分、`correction.subns` 为正的小数部分，脚本使用 Python `Fraction` 合成为 scaled-ns 精确比较，避免用浮点近似掩盖亚纳秒错误。完整逐字段期望值与实际值在验证 JSON 内。

复现命令：

```sh
python3 scripts/verify_wire_reference.py
# 或使用另一台机器已安装的官方工具：
python3 scripts/verify_wire_reference.py --tshark /absolute/path/to/tshark
```

脚本只使用 Python 标准库和外部 TShark，不导入项目解析器，也不执行 MoonBit 产品代码。期待值是脚本中显式写出的六帧契约；PCAP 中 PTP payload 与实际 fixture 字节相同。以太网头与最小帧 padding 只用于传输封装，padding 不计入 PTP `messageLength`。双遍 `-2` 使前面的 Sync 可以引用后面已经出现的 Follow_Up；不把第一遍暂时未观察到 Follow_Up 的分析提示当成错误。

本机此前没有 TShark，现已从 [Wireshark 官方目录](https://www.wireshark.org/download/osx/all-versions/Wireshark%204.6.9.dmg) 下载，并安装在用户私有工具目录 `~/.local/share/ptp-audit-tools/Wireshark.app`。安装包 SHA256 为 `10bd54ccdc3f40457f6a1f0c517bc93703fcb327c4cd4b93002e7a623dacbf38`，与 [官方发布摘要](https://www.wireshark.org/download/SIGNATURES-4.6.9.txt) 一致。二进制包含 arm64 和 x86_64，版本标识为 `v4.6.9-0-g2d548b197c75`。下载来源、工具和源码摘要保存在 [tool-installation.json](../research/wire-reference/tool-installation.json)；保存了官方摘要文本，但不声称独立验证过其 PGP 签名。

TShark 采用 GPL-2.0-or-later，由脚本作为外部进程运行，没有链接入产品，也未将其应用包或安装镜像打包分发。Wireshark 的新版 dissector 同时理解 2008/2019，部分字段用新版名称 `majorSdoId`/`minorSdoId` 展示；本次实际核对的字节均是 2008 固定格式，不能因此推断已支持 2019。

本轮按官方解释补充了两个产品范围门禁：非 Sync 的 twoStepFlag 置位由 `WIRE.TWO_STEP_FLAG` 拒绝；对官方解释 #25/#27 存在冲突的两种 tooBig 编码（INT64_MAX 与 -1/all-ones），由 `SCOPE.CORRECTION_TOO_BIG` 统一返回 Unsupported，避免输出无依据的精确测量。它们使用独立的边界/负例验证，不能从上表六个正常报文的 130 项工具字段核对推断通过。

规则的规范定位、项目证据政策和仍需授权规范全文核对的具体边界，见 [逐规则依据表](rule-traceability.md)。
