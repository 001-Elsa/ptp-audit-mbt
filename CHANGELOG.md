# Changelog

## 2026-10-22 publication preparation for 001-Elsa/ptp-audit 0.3.0

- Set the publishable module namespace to `001-Elsa/ptp-audit`, updated all package imports/generated interfaces, and set the real GitHub repository metadata. Added registry consumer installation and source links.
- Prepared a clean public history on the existing GitLink initialization commit, grouped by real engineering content and pushed in multiple batches. Older development objects containing a withdrawn capture are excluded; the complete local development history is preserved separately.
- Synchronized current documentation with the newly authorized three-platform release workflow. Remote refs, registry package content and Actions results are verified separately in `research/publication/current.json`; official contest registration is still handled by the participant.
- Added byte-bound compact registry staging that omits research evidence after the registry rejected the full 41 MB archive with HTTP 413. Both Git repositories and the full source ZIP retain that evidence; the product, tests, docs and proposal bytes remain identical.
- Preserve the user-provided Markdown title link as a clickable PDF link, without displaying Markdown syntax in the proposal.

## 2026-10-22 local submission preparation on 0.3.0

- Prepared the October Hackathon proposal, editable one-page source and PDF, current website requirement record, and local submission bundle. Personal fields are omitted at the user's request; the local packaging tools do not publish; platform delivery is now covered by the release entry above, while official registration is handled by the participant.
- Withdrew the external Wireshark sample from the current source/delivery tree where redistribution permission was not established. Retained provenance metadata, synthetic project fixtures and a packaging rejection test; historical Git objects are excluded from delivery.
- Unified CI with the full local validator, including commissioning, rule evidence and clean archive checks. Added source/document hash binding, public interface/schema/count/link checks and one-page PDF provenance validation.
- The existing additive domain enhancement below is included in this local source freeze. Current counts are 6,004 effective production MoonBit lines, 455 tests per backend and 169 CLI fixtures plus 7 boundaries; these supersede the original baseline figures only for the current enhancement. The passing logs and exact scope are in docs/validation.md.

## Additive enhancement included in the 0.3.0 release

- Added a PTP-specific correction ledger for every admitted E2E quartet. It reconstructs the uncorrected result, the signed contribution of Sync, Follow_Up and Delay_Resp, the excluded Delay_Req operand, and the corrected result using exact integers.
- Added optional `error_budget` input to `ptp-audit/v1` and additive `metrology` output to `ptp-audit-report/v2`. Caller-supplied timestamp, aggregate correction and full path-asymmetry bounds produce a conditional interval and `within_limit`, `outside_limit` or `indeterminate` application verdict. An application threshold failure does not become a protocol violation.
- Added `commission`, `ptp-commission/v1`, `ptp-commission-report/v1` and the library `commission_json` entry. A campaign binds a verified selected Announce sender/receiver to an explicit measured quartet in the same context and declared selection interval, then distinguishes immediate-sender and GM changes between accepted adjacent steps.
- Added synthetic operational cases for a valid upstream change, a valid exchange from the wrong selected master, a sender change under one GM, a new GM behind the same sender, missing continuity/stability evidence, correction accounting and application-budget boundaries. The independent Python verifier decodes actual payload bytes and uses `Fraction` to check the MoonBit CLI results.
- Added the practical operating guide in [`docs/commissioning.md`](docs/commissioning.md) and reproducible commands in [`examples/commissioning.md`](examples/commissioning.md). No hardware capture, calibration, inferred failover duration, cross-GM offset delta or full IEEE conformance is claimed.
- This enhancement is included in the current 0.3.0 publication sources. Generic interval arithmetic, temporal processing, witnesses and reports are known ecosystem neighbors; differentiation is the concrete PTP selected-Announce/quartet/correction chain, subject to the recorded originality-review limits.

The verification figures under the original 0.3.0 entry below describe its frozen baseline. Current enhancement checks and evidence are recorded in [`docs/validation.md`](docs/validation.md) and [`research/commissioning/manifest.json`](research/commissioning/manifest.json).

## 0.3.0

### Added

- Added explicit observation samples, epochs, capture windows, clock domains, and completeness policies.
- Added bounded pending Sync/Follow_Up and Delay_Req/Delay_Resp lifecycle handling with caller-supplied deadlines. A missing message remains insufficient evidence unless a complete observation window covers its deadline.
- Added BMCA snapshot validation for decision time, Announce validity and source, candidate observation context, eligibility, and capture-window confirmation.
- Added evidence-rich `ptp-audit-report/v2` output while keeping the case input at `ptp-audit/v1`.
- Expanded the fixture manifest to 116 cases for observation, lifecycle, snapshot, and evidence paths.
- Added an independent TShark wire reference record for six constructed frames, five message types, and 130 decoded field checks.

### Scope and verification notes

- The complete authorized IEEE 1588-2008 text has not been obtained. The registered official references and independent implementations provide only the documented rule-level support; they do not establish full IEEE conformance.
- Local `check --target all --deny-warn`, 430 tests on each of native, JS, wasm, and wasm-gc (1,720 executions total), the 116-case CLI regression plus 7 I/O boundaries, `moon info`, and `moon fmt --check` passed. Logs are recorded in [`docs/validation.md`](docs/validation.md).
- Historical baseline status: this work was originally local only, with no source push or registry release. The user renewed publication authorization on 2026-10-22; the current release entry and remote publication receipt supersede that earlier scope. Formal registration is separate.
- The measured product size is 4,253 effective MoonBit lines, excluding tests, research, build outputs, blank lines, and full-line comments. The charter's 4–10k range is a reference; no filler or synthetic history is added to meet it.

- Fixed independent-review counterexamples: blank event clock/validity source, invalid unused assumption types, and duplicate/conflicting exchange claims cannot manufacture valid evidence or repeated measurements.
- Added `validate_local.py` and `package_local.py` to reproduce the local gates and verify a clean extracted delivery without any remote operations.
