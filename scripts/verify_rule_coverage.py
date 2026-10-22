#!/usr/bin/env python3
"""Run rule-focused public API/byte negatives and record actual Moon test output.

This is a test-execution inventory, not branch coverage or IEEE certification.
CLI-rule evidence remains a separately generated inventory with its own hash.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[1]
TESTS = (
    "tests/rule_coverage_test.mbt",
    "exchange/rule_resource_wbtest.mbt",
)
OUT = ROOT / "research/normative-completion"
INVENTORY = OUT / "rule-inventory.json"
SCRIPT = Path(__file__).resolve()
EXCLUDED_DIRECTORIES = {
    ".git", ".moon", ".mooncakes", "_build", "node_modules", "research",
}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_snapshot() -> list[dict[str, str]]:
    # Include every formal package and its tests/helpers, not just the files
    # containing named rules. Added/deleted files also change this snapshot.
    paths = {SCRIPT, ROOT / "scripts/moon-local"}
    for parent, directories, filenames in os.walk(ROOT):
        directories[:] = sorted(
            directory for directory in directories
            if directory not in EXCLUDED_DIRECTORIES
        )
        for name in filenames:
            if (
                name.endswith((".mbt", ".mbti", ".mbt.md"))
                or name in {"moon.mod", "moon.mod.json", "moon.pkg", "moon.pkg.json"}
            ):
                paths.add(Path(parent) / name)
    return [
        {"path": str(path.relative_to(ROOT)), "sha256": digest(path)}
        for path in sorted(paths)
    ]


def validate_inventory(path: Path, root: Path) -> tuple[dict, dict]:
    """Authenticate all inventory-declared source hashes against current files.

    A stale inventory remains historical evidence only. Its CLI observations
    must not be combined with fresh typed tests into a current coverage claim.
    """
    errors = []
    checks = []
    inventory = {}
    sha256 = None
    try:
        raw = path.read_bytes()
        sha256 = hashlib.sha256(raw).hexdigest()
        inventory = json.loads(raw)
        if not isinstance(inventory, dict):
            raise ValueError("inventory root must be an object")
    except (OSError, ValueError, TypeError) as error:
        errors.append(f"inventory could not be read: {error}")
        return {}, {"valid": False, "sha256": sha256, "source_checks": [], "errors": errors}
    declared = inventory.get("sources")
    if not isinstance(declared, list) or not declared:
        errors.append("inventory.sources must be a nonempty list")
        declared = []
    seen = set()
    root = root.resolve()
    for entry in declared:
        if not isinstance(entry, dict):
            errors.append("inventory source entry must be an object")
            continue
        name = entry.get("path")
        expected = entry.get("sha256")
        if not isinstance(name, str) or not name:
            errors.append("inventory source path must be nonempty")
            continue
        if name in seen:
            errors.append(f"duplicate inventory source path: {name}")
        seen.add(name)
        if not isinstance(expected, str) or not re.fullmatch(r"[0-9a-f]{64}", expected):
            errors.append(f"invalid inventory source SHA-256: {name}")
            continue
        candidate = root / name
        try:
            if Path(name).is_absolute() or not candidate.resolve().is_relative_to(root):
                raise ValueError("source path must stay inside the project")
            actual = digest(candidate)
        except (OSError, ValueError) as error:
            errors.append(f"cannot verify inventory source {name}: {error}")
            actual = None
        matching = actual == expected
        checks.append({
            "path": name,
            "inventory_sha256": expected,
            "current_sha256": actual,
            "matching": matching,
        })
        if not matching:
            errors.append(f"inventory source hash mismatch: {name}")
    rules = inventory.get("rules")
    if not isinstance(rules, list) or not rules:
        errors.append("inventory.rules must be a nonempty list")
    elif any(
        not isinstance(rule, dict)
        or not isinstance(rule.get("rule"), str)
        or not isinstance(rule.get("cli_observed_fixtures"), list)
        for rule in rules
    ):
        errors.append("inventory rules must name rules and explicit CLI observation lists")
    return inventory, {
        "valid": not errors,
        "sha256": sha256,
        "source_checks": checks,
        "errors": errors,
    }


def coverage_union(
    inventory: dict, validation: dict, executed: set[str], tests_successful: bool,
) -> dict:
    valid = validation["valid"] and tests_successful
    if not valid:
        return {
            "established": False,
            "cli_or_this_run_observed_rule_count": None,
            "without_either_runtime_evidence": None,
            "reason": "Current union not established: source-validated inventory and successful stable test execution are both required.",
        }
    implemented = {entry["rule"] for entry in inventory["rules"]}
    cli = {
        entry["rule"] for entry in inventory["rules"]
        if entry["cli_observed_fixtures"]
    }
    return {
        "established": True,
        "implemented_rule_count": len(implemented),
        "cli_observed_rule_count": len(cli),
        "cli_or_this_run_observed_rule_count": len((cli | executed) & implemented),
        "without_either_runtime_evidence": sorted(implemented - cli - executed),
    }


def self_test() -> None:
    """Reject stale/missing/outside/malformed sources without editing the repo."""
    with tempfile.TemporaryDirectory(prefix="ptp-rule-inventory-self-test-") as temp:
        root = Path(temp)
        source = root / "wire.mbt"
        source.write_text("original source\n")
        inventory_path = root / "inventory.json"
        original = {
            "sources": [{"path": "wire.mbt", "sha256": digest(source)}],
            "rules": [{"rule": "WIRE.EXAMPLE", "cli_observed_fixtures": ["historical"]}],
        }
        inventory_path.write_text(json.dumps(original))
        inventory, validation = validate_inventory(inventory_path, root)
        if not validation["valid"] or not coverage_union(inventory, validation, set(), True)["established"]:
            raise AssertionError("fresh inventory must establish its rule-name union")
        source.write_text("changed source\n")
        inventory, validation = validate_inventory(inventory_path, root)
        union = coverage_union(inventory, validation, {"TYPED.PASSED"}, True)
        if validation["valid"] or union["established"] or union["cli_or_this_run_observed_rule_count"] is not None:
            raise AssertionError("stale source must fail even when fresh typed tests passed")
        source.unlink()
        if validate_inventory(inventory_path, root)[1]["valid"]:
            raise AssertionError("missing source must fail")
        for malformed_sources in [
            [],
            [{"path": "../outside.mbt", "sha256": "0" * 64}],
            [{"path": "wire.mbt", "sha256": "not-a-hash"}],
        ]:
            inventory_path.write_text(json.dumps({**original, "sources": malformed_sources}))
            if validate_inventory(inventory_path, root)[1]["valid"]:
                raise AssertionError("invalid source declarations must fail")
        inventory_path.write_text("not JSON")
        if validate_inventory(inventory_path, root)[1]["valid"]:
            raise AssertionError("malformed inventory must fail")
    print("self-test: fresh accepted; stale, missing, unsafe and malformed sources rejected; stale union withheld")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--targets",
        nargs="+",
        choices=("native", "js", "wasm", "wasm-gc"),
        default=["native", "js", "wasm", "wasm-gc"],
    )
    parser.add_argument(
        "--self-test", action="store_true",
        help="Run inventory-validation self-checks only; do not modify project evidence.",
    )
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    OUT.mkdir(parents=True, exist_ok=True)
    sources = source_snapshot()
    inventory, inventory_before = validate_inventory(INVENTORY, ROOT)
    version_command = ["scripts/moon-local", "version", "--all"]
    toolchain = subprocess.run(
        version_command, cwd=ROOT, capture_output=True, text=True, check=False,
    )
    version_output = toolchain.stdout + toolchain.stderr
    version_ok = toolchain.returncode == 0 and "moonc " in version_output
    expected = {}
    for path in TESTS:
        text = (ROOT / path).read_text()
        for name in re.findall(r'^test "(rule coverage [^"]+)"', text, re.M):
            rule = name.removeprefix("rule coverage ").split(" ", 1)[0]
            if rule in expected:
                raise SystemExit(f"duplicate test rule: {rule}")
            expected[rule] = {"rule": rule, "test": name, "path": path}
    if not expected:
        raise SystemExit("no rule tests found")
    runs = []
    success = True
    for target in dict.fromkeys(args.targets):
        command = [
            "scripts/moon-local", "test", *TESTS, "--target", target,
            "--deny-warn", "--verbose",
        ]
        completed = subprocess.run(
            command, cwd=ROOT, capture_output=True, text=True, check=False,
        )
        output = completed.stdout + completed.stderr
        log = OUT / f"rule-tests-{target}.log"
        log.write_text(output)
        passed = re.findall(r'\("(rule coverage [^"]+)"\) ok\s*$', output, re.M)
        wanted = {entry["test"] for entry in expected.values()}
        actual = set(passed)
        summary = re.search(r"Total tests: (\d+), passed: (\d+), failed: (\d+)\.", output)
        counts = list(map(int, summary.groups())) if summary else None
        ok = (
            completed.returncode == 0
            and actual == wanted
            and len(passed) == len(expected)
            and counts == [len(expected), len(expected), 0]
        )
        runs.append({
            "target": target,
            "command": command,
            "exit_code": completed.returncode,
            "successful": ok,
            "test_count": len(expected),
            "runtime_passed_tests": passed,
            "missing_tests": sorted(wanted - actual),
            "unexpected_tests": sorted(actual - wanted),
            "log": str(log.relative_to(ROOT)),
            "log_sha256": digest(log),
        })
        print(f"{target}: {len(passed)}/{len(expected)} rule tests, successful={ok}")
        success = success and ok
        if not ok:
            print(output, file=sys.stderr)
            break
    stable = sources == source_snapshot()
    tests_successful = success and stable
    inventory_after, inventory_validation = validate_inventory(INVENTORY, ROOT)
    inventory_stable = inventory_before["sha256"] == inventory_validation["sha256"]
    if not inventory_stable:
        inventory_validation["valid"] = False
        inventory_validation["errors"].append("inventory changed during test execution")
    inventory_validation["unchanged_during_run"] = inventory_stable
    inventory_validation["valid_before_run"] = inventory_before["valid"]
    if not inventory_before["valid"]:
        inventory_validation["valid"] = False
        inventory_validation["errors"] = sorted(set(
            inventory_validation["errors"] + inventory_before["errors"],
        ))
    union = coverage_union(inventory_after, inventory_validation, set(expected), tests_successful)
    success = tests_successful and version_ok and inventory_validation["valid"]
    evidence = {
        "schema": "ptp-audit/rule-test-execution/v2",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "scope": "Explicit rule assertions from public typed APIs and independent byte negatives; internal replay resource defense is separately identified as whitebox.",
        "boundary": "A passed test proves its concrete assertions executed. It is not exhaustive branch coverage, full protocol conformance or a substitute for licensed normative text.",
        "sources": sources,
        "sources_unchanged_during_run": stable,
        "runner": {"path": str(SCRIPT.relative_to(ROOT)), "sha256": digest(SCRIPT)},
        "toolchain": {
            "command": version_command,
            "exit_code": toolchain.returncode,
            "version_output": version_output,
            "version_observed": version_ok,
        },
        "typed_rule_tests_successful": tests_successful,
        "successful": success,
        "rule_count": len(expected),
        "test_executions": sum(len(run["runtime_passed_tests"]) for run in runs),
        "rules": sorted(expected.values(), key=lambda entry: entry["rule"]),
        "runs": runs,
    }
    evidence["referenced_cli_inventory"] = {
        "path": str(INVENTORY.relative_to(ROOT)),
        "sha256": inventory_validation["sha256"],
        "generated_at_utc": inventory.get("generated_at_utc"),
        "boundary": "CLI observations are usable only when every declared source SHA-256 matches current files and the inventory stays unchanged during this run. A union counts rule names, not every predicate or branch.",
        "validation": inventory_validation,
        **union,
    }
    destination = OUT / "test-coverage.json"
    destination.write_text(json.dumps(evidence, ensure_ascii=False, indent=2) + "\n")
    print(destination.relative_to(ROOT))
    if not inventory_validation["valid"]:
        print("inventory validation failed; fresh typed-test results are retained, current CLI union is withheld", file=sys.stderr)
        for error in inventory_validation["errors"]:
            print(error, file=sys.stderr)
    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
