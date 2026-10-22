# Independent implementation reference

This directory contains unmodified excerpts downloaded from LinuxPTP v4.4 on 2026-10-19 for rule review only. Files carry the GPL-2.0-or-later notices from upstream; they are not linked or copied into the Apache-2.0 MoonBit product. The project independently expresses the bounded subset and does not claim LinuxPTP conformance.

`bmca-oracle.c` and `bmca-vectors.json` are research-only artifacts. The C harness is compiled separately from the preserved upstream source and emits 219 deterministic comparison results. `tests/reference_test.mbt` checks the MoonBit result and decision branch against those results; the harness is never linked into the library or CLI.
