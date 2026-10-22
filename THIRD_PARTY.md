# Third-party sources and boundaries

The MoonBit library, Node CLI adapter, fixture generators, and project documentation use the repository Apache-2.0 license unless a file explicitly states otherwise. Standard protocol and comparison rules are not claimed as newly invented algorithms.

`wire.to_hex` delegates to `moonbitlang/core/encoding/hex.encode` from the installed MoonBit standard library (Apache-2.0); the dependency is declared in `wire/moon.pkg`. This replaces the project's own hexadecimal alphabet loop after the source review identified the same generic alphabet sequence in two published packages. Standard-library functionality is reused and attributed rather than claimed as project-specific novelty.

`research/implementation-reference/linuxptp-v4.4-{msg.h,bmc.c,bmc.h,port.c}` retain upstream copyright and GPL-2.0-or-later notices. Source URLs are `https://raw.githubusercontent.com/richardcochran/linuxptp/v4.4/<file>`. `COPYING.linuxptp` is the upstream license. The extracted `bmca-oracle.c` test harness is GPL-2.0-or-later reference material; it is compiled as a separate executable during vector generation and is never linked into the product. Generated result data and MoonBit assertions do not copy C function bodies.

The externally downloaded Wireshark `ptpv2.pcap` has been removed from the working tree and delivery because a redistribution grant was not established. Only its public source URL, historical hash and limitations remain in `research/wireshark/README.md`. It is not a required input, is not redistributed, and has never been part of the passing acceptance fixtures. The shipped `research/wire-reference/complete-audit.pcap` is independently generated synthetic project data and is covered by Apache-2.0. An old Git commit may still contain the withdrawn external sample; Git history is not included in the submission archive and must not be published unchanged as a claim of redistribution permission.

Mooncakes source archives in `research/2026-10-19*/source-review/` are third-party review artifacts with their own embedded licenses. They are not product dependencies and were not executed. Root-page snapshots and audit metadata are evidence of a dated review, not a declaration of rights over their contents.

The expanded whole-index review stores downloaded Mooncakes ZIPs outside the repository at `~/.local/share/ptp-audit-tools/mooncakes-source-cache`. `research/full-source-audit/` and `research/originality-completion/` contain the fixed module inventory, file hashes, limited review excerpts and classifications. They do not relicense upstream source or add registry packages as product dependencies. Neither archive scanning nor clone screening builds or runs the inspected packages.

The official MoonBit toolchain is installed in the user's tool directory, outside the product source. The pinned download URL and SHA-256 are recorded in `research/toolchain-repair/manifest.json`; no compiler binaries are repackaged as this project's code.

The external Wireshark/TShark 4.6.9 installation used by `scripts/verify_wire_reference.py` remains outside this module. It is invoked as a separate process for sample field verification, is not linked into the MoonBit library and is not repackaged in the local delivery. The verified vendor download and tool hashes are recorded in `research/wire-reference/tool-installation.json`. The six-frame `complete-audit.pcap` in that directory is synthetic project-generated fixture data; it is distinct from the external supplementary Wireshark capture above.

Official IEEE interpretations, the IEC authorized preview and IEEE802 contributions are referenced by URL, page and SHA-256 in `research/wire-reference/sources/README.md`. Only reviewed facts and limitations are recorded; the copyrighted full documents are not bundled or relicensed under Apache-2.0. These materials and the LinuxPTP reference do not constitute a complete normative review or conformity certificate.

The official IEEE802-hosted 2008 Garner tutorial is registered in `research/normative-completion/source-access.json`. It supplies a separately reviewed explanation of timestamp widths, scaled correction, quality precedence and dataset comparison flowcharts. It is a tutorial, not the complete IEEE 1588 normative standard. The PDF cache remains outside this project; tests use independently written inputs and assertions rather than copied tutorial graphics or text.

## Tested standard library revision

The verified official MoonBit Core checkout is `eb321a18f7a33d37114546682a8d1cd6658afab8` (2026-10-16), without local modifications, from https://github.com/moonbitlang/core. Its strict JSON duplicate-key option is required. CI checks out and bundles this exact revision separately from the compiler archive because the historical compiler bundle contains an older Core API. Core remains a toolchain component and is not vendored into this project.
