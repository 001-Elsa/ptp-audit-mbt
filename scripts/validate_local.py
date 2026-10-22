#!/usr/bin/env python3
"""Run the local delivery gates and retain exact commands/results. Never publishes."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fixture_hashes() -> dict[str, str]:
    paths = list((ROOT / "fixtures").rglob("*.json")) + list((ROOT / "tests").glob("*.mbt"))
    return {str(path.relative_to(ROOT)): sha(path) for path in sorted(paths)}


def gate_source_hashes() -> dict[str, str]:
    paths = set((ROOT / "scripts").rglob("*.py"))
    paths.update({ROOT / "scripts/moon-local", ROOT / "research/normative-completion/build_rule_inventory.py"})
    return {str(path.relative_to(ROOT)): sha(path) for path in sorted(paths)}


def product_source_hashes() -> dict[str, str]:
    paths = [
        path for path in ROOT.rglob("*")
        if path.is_file()
        and (path.suffix in {".mbt", ".mjs"} or path.name in {"moon.mod", "moon.pkg"})
        and not {"_build", "target", ".git", ".mooncakes", "research"}.intersection(path.relative_to(ROOT).parts)
    ]
    return {str(path.relative_to(ROOT)): sha(path) for path in sorted(paths)}


def product_lines() -> dict[str, int]:
    excluded = {"_build", "target", "research", "tests", ".git", ".mooncakes"}
    return {
        str(path.relative_to(ROOT)): sum(
            bool(line.strip()) and not line.lstrip().startswith("//")
            for line in path.read_text().splitlines()
        )
        for path in sorted(ROOT.rglob("*.mbt"))
        if not excluded.intersection(path.relative_to(ROOT).parts)
        and not path.name.endswith(("_test.mbt", "_wbtest.mbt"))
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--with-wire", action="store_true", help="Also invoke the separately installed TShark")
    parser.add_argument("--output", type=Path, default=ROOT / "research/validation-0.3.0")
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    steps = []

    def run(label: str, command: list[str]) -> None:
        result = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        (output / f"{label}.log").write_text(result.stdout)
        steps.append({"label": label, "command": command, "exit": result.returncode, "log": f"{label}.log"})
        print(f"{label}: {'pass' if result.returncode == 0 else 'FAIL'}", flush=True)
        if result.returncode:
            raise RuntimeError(f"{label} failed; see {output / (label + '.log')}")

    error = None
    gate_sources_before = gate_source_hashes()
    product_sources_before = product_source_hashes()
    try:
        before = fixture_hashes()
        run("generate-fixtures", [sys.executable, "scripts/build_acceptance_fixtures.py"])
        run("generate-reference", [sys.executable, "scripts/build_reference_vectors.py"])
        run("generate-operational", [sys.executable, "scripts/build_commissioning_fixtures.py"])
        run("generate-format", ["scripts/moon-local", "fmt"])
        after = fixture_hashes()
        changed = sorted(key for key in before.keys() | after.keys() if before.get(key) != after.get(key))
        (output / "regeneration.json").write_text(json.dumps({"stable": not changed, "changed": changed}, indent=2) + "\n")
        if changed:
            raise RuntimeError("Fixture regeneration changed committed inputs/tests: " + ", ".join(changed))
        run("check-all", ["scripts/moon-local", "check", "--target", "all", "--deny-warn"])
        run("test-all", ["scripts/moon-local", "test", "--target", "all", "--deny-warn"])
        run("cli-fixtures", [sys.executable, "scripts/verify_cli_fixtures.py"])
        run("report-evidence", [sys.executable, "scripts/verify_report_evidence.py"])
        run("operational-evidence", [sys.executable, "scripts/verify_commissioning.py"])
        run("rule-inventory", [sys.executable, "research/normative-completion/build_rule_inventory.py"])
        run("rule-coverage", [sys.executable, "scripts/verify_rule_coverage.py"])
        run("originality-scanner-self-test", [sys.executable, "scripts/verify_source_originality.py", "--self-test"])
        run("package-local-self-test", [sys.executable, "scripts/test_package_local.py"])
        if args.with_wire:
            run("wire-reference", [sys.executable, "scripts/verify_wire_reference.py"])
        # The final source/interface operations are deliberately in this order.
        run("info", ["scripts/moon-local", "info"])
        run("fmt", ["scripts/moon-local", "fmt"])
        run("fmt-check", ["scripts/moon-local", "fmt", "--check"])
    except (RuntimeError, OSError) as exception:
        error = str(exception)
        print(error, file=sys.stderr)
    gate_sources_after = gate_source_hashes()
    product_sources_after = product_source_hashes()
    if gate_sources_before != gate_sources_after:
        error = "Validation gate source changed during the run; rerun after scripts are frozen"
        print(error, file=sys.stderr)
    if product_sources_before != product_sources_after:
        error = "Product source changed during the run; rerun after sources are frozen"
        print(error, file=sys.stderr)
    counts = product_lines()
    tests = []
    if (output / "test-all.log").exists():
        tests = [
            {"total": int(a), "passed": int(b), "failed": int(c), "target": target}
            for a, b, c, target in re.findall(
                r"Total tests: (\d+), passed: (\d+), failed: (\d+)\. \[([^]]+)\]",
                (output / "test-all.log").read_text(),
            )
        ]
    manifest = {
        "version": "0.3.0", "scope": "local project only; no remote operations or registry publication",
        "result": "pass" if error is None else "fail", "error": error, "commands": steps,
        "backend_tests": tests, "fixture_count": len(json.loads((ROOT / "fixtures/manifest.json").read_text())["cases"]),
        "product_effective_moonbit_lines": sum(counts.values()), "product_lines_by_file": counts,
        "line_count_policy": "Exclude tests/research/build and blank/full-line comment lines; not a quality metric",
        "source_sha256": product_sources_before,
        "sources_unchanged_during_run": product_sources_before == product_sources_after,
        "gate_source_sha256": gate_sources_before,
        "gate_sources_unchanged_during_run": gate_sources_before == gate_sources_after,
        "fixture_manifest_sha256": sha(ROOT / "fixtures/manifest.json"),
        "operational_fixture_manifest_sha256": sha(ROOT / "fixtures/commissioning/manifest.json"),
        "operational_report_sha256": sha(ROOT / "research/commissioning/manifest.json") if (ROOT / "research/commissioning/manifest.json").exists() else None,
        "not_certified": ["full IEEE normative conformity", "capture authenticity", "absolute timing accuracy", "competition originality or external submission"],
    }
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
    return 0 if error is None else 1


if __name__ == "__main__":
    raise SystemExit(main())
