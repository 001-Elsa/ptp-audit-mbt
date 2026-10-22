# Published-module consumer smoke test

This independent module installed `001-Elsa/ptp-audit@0.3.0` from the public registry. It calls both root JSON entrypoints with valid synthetic input and malformed input, parses the actual returned JSON, and asserts the root schema and status. Four tests passed on native, JS, wasm and wasm-gc (16 executions).

Use the compiler/Core pairing recorded in the root README, then run `moon test --target all --deny-warn` from this directory. `install.log` records registry installation and `tests.log` records the backend results. The sample payloads are project-generated; no external capture is used.
