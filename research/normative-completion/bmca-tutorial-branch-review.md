# BMCA public tutorial branch review

On 2026-10-19, the reviewer rendered and visually inspected complete pages 61 and 62 of Geoffrey M. Garner's *IEEE 1588 Version 2*, hosted on the official IEEE 802.1 public-contribution server. Expectations below were transcribed from the displayed flow arrows and then checked against `bmca/bmca.mbt`. This is a separately inspected, non-normative reference; it is not an authorized complete IEEE 1588-2008 text.

Source ID: `ieee802-garner-1588v2-tutorial-2008`.

URL: <https://www.ieee802.org/1/files/public/docs2008/as-garner-1588v2-summary-0908.pdf>.

The complete source is 89 pages and 3,623,113 bytes; SHA-256 `a023d1d55e20fe4b3ea5dbf11cdcfd650abfa071c3cab11e8247de6ff4eece68`. The full PDF and rendered page images remain outside the project archive.

| Source page and branch | Diagram outcome | Implementation rule |
| --- | --- | --- |
| p61, different GM | First unequal field decides; smaller value wins. Precedence: priority1, clockClass, clockAccuracy, offsetScaledLogVariance, priority2, clockIdentity. | `BMCA.DIFFERENT_GM.*` |
| p62, `A.steps + 1 < B.steps` | A better, without topology flag. | `BMCA.SAME_GM.stepsRemoved` |
| p62, `A.steps > B.steps + 1` | B better, without topology flag. | `BMCA.SAME_GM.stepsRemoved` |
| p62, steps differ by one; receiver of longer path < its sender | Shorter path better, without topology flag. Checked with either A or B as longer path. | `BMCA.SAME_GM.oneHop` |
| p62, steps differ by one; receiver of longer path > its sender | Shorter path better by topology. Checked with either A or B as longer path. | `BMCA.SAME_GM.oneHop` |
| p62, steps differ by one; receiver of longer path = its sender | error-1. Checked with either A or B as longer path. | `BMCA.SAME_GM.error1` |
| p62, equal steps, unequal senders | Smaller sender better by topology, both directions. | `BMCA.SAME_GM.sender` |
| p62, equal steps and senders, unequal receiver ports | Smaller receiver port better by topology, both directions. | `BMCA.SAME_GM.receiverPort` |
| p62, equal steps, senders and receiver ports | error-2. | `BMCA.SAME_GM.error2` |

All inspected directions agree with the current implementation. No production correction was justified. The implementation maps the diagram's error-1 and error-2 to an unresolved, `Unsupported` result and reports no preferred side; this is an explicit product boundary, not a claim that the diagram mandates the product's diagnostic vocabulary.

The independent test file `bmca/tutorial_flow_wbtest.mbt` contains six quality-precedence tests, each in both comparison directions, plus thirteen same-GM outcome cases: **19 tests and 25 actual dataset comparisons per backend**. Each quality test deliberately makes lower-priority fields prefer the opposite candidate, so passing requires the precedence shown by the diagram.

Actual verification:

```text
scripts/moon-local test bmca --target all --deny-warn
wasm     19 passed, 0 failed
wasm-gc  19 passed, 0 failed
js       19 passed, 0 failed
native   19 passed, 0 failed
```

That is 76 test executions and 100 dataset comparisons across four backends. The machine-readable case ledger, expected side/topology and source classification are in `bmca-tutorial-branch-review.json`.

This review does not establish foreign-master qualification, complete snapshot eligibility, every port-state decision, profile conformance, or full licensed-standard consistency. Those claims cannot be inferred by treating a tutorial diagram as the complete standard.
