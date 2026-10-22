// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "001-Elsa/ptp-audit"

version = "0.3.0"

readme = "README.md"

repository = "https://github.com/001-Elsa/ptp-audit-mbt"

license = "Apache-2.0"

keywords = [
  "ptp",
  "ieee1588",
  "ptp-audit",
  "ieee1588-2008",
  "two-step",
  "bmca-dataset",
  "moonbit",
]

preferred_target = "wasm"

description = "Bounded offline IEEE 1588-2008 PTP two-step association and scoped BMCA dataset-decision auditor."
