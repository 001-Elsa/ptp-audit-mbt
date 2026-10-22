#!/usr/bin/env python3
"""Create and smoke-test a local MoonBit ZIP; never logs in, pushes or publishes."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "_build/publish"
BACKENDS = {"native", "js", "wasm", "wasm-gc"}
EXECUTABLES = {"bin/ptp-audit.mjs", "scripts/moon-local"}
FORBIDDEN_PARTS = {".git", "_build", "target", ".mooncakes", ".moonagent", "__pycache__", "source-review", "pages", ".venv"}
FORBIDDEN_FILES = {"research/wireshark/ptpv2.pcap"}
SOURCE_EXCLUSIONS = {"_build", "target", ".git", ".mooncakes", "research"}
REQUIRED_COMMANDS = {"generate-fixtures", "generate-reference", "generate-operational", "generate-format", "check-all", "test-all", "cli-fixtures", "report-evidence", "operational-evidence", "rule-inventory", "rule-coverage", "originality-scanner-self-test", "package-local-self-test", "info", "fmt", "fmt-check"}
REQUIRED_FOLDERS = (
    "audit", "wire", "exchange", "observation", "bmca", "evidence", "diagnostic", "cmd", "metrology", "commissioning",
    "tests", "fixtures", "scripts", "docs", "examples", ".github",
    "research/normative-completion", "research/full-source-audit", "research/originality-completion",
    "research/wire-reference", "research/implementation-reference", "research/core-review",
    "research/2026-10-19-release-review",
    "research/commissioning",
    "research/delivery", "research/contest-2026-10-22", "output/pdf",
)


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def file_digest(path: Path) -> str:
    return digest(path.read_bytes())


def validation_source(path: Path, root: Path) -> bool:
    # Keep identical to validate_local.py: source, JS I/O wrapper and Moon manifests.
    return (path.is_file()
            and (path.suffix in {".mbt", ".mjs"} or path.name in {"moon.mod", "moon.pkg"})
            and not SOURCE_EXCLUSIONS.intersection(path.relative_to(root).parts))


def safe_name(name: str) -> PurePosixPath:
    path = PurePosixPath(name)
    if (not name or "\\" in name or "\x00" in name or path.is_absolute()
            or ".." in path.parts or re.match(r"^[A-Za-z]:", name)
            or str(path) != name.rstrip("/") or str(path) == "."):
        raise RuntimeError(f"Unsafe/noncanonical archive path: {name!r}")
    return path


def required_files(root: Path, version: str) -> set[str]:
    required = {
        "moon.mod", "moon.pkg", "facade.mbt", "pkg.generated.mbti", ".moonignore", "AGENTS.md",
        "README.md", "README.mbt.md", "LICENSE", "THIRD_PARTY.md", "CHANGELOG.md", *EXECUTABLES,
        "PROJECT_APPLICATION.md", "SUBMISSION.md",
        "output/pdf/ptp-audit-项目申报书.pdf", "output/pdf/ptp-audit-项目申报书.verification.json",
        "research/full-source-audit/index.json", "research/full-source-audit/modules.json",
        "research/full-source-audit/manifest.json", "research/normative-completion/source-access.json",
        "research/full-source-audit/verification.json", "research/full-source-audit/verify_manifest.py",
        "research/full-source-audit/supplemental-binary-text.json",
        "research/full-source-audit/supplemental_binary_text_scan.py",
        "research/full-source-audit/text-source-nul-review.json",
        "research/full-source-audit/audit_source_nul.py",
        "research/full-source-audit/text-source-nul-review-recheck-summary.json",
        "research/normative-completion/rule-inventory.json", "research/normative-completion/test-coverage.json",
        "fixtures/commissioning/manifest.json", "research/commissioning/manifest.json",
        "research/originality-completion/full-source-clone-screen-40.json",
        "research/originality-completion/full-source-clone-screen-80.json",
        "research/originality-completion/full-source-semantic-review.json",
        "research/originality-completion/final-neighbor-review-coverage.json",
        "research/originality-completion/supplemental-source-semantic-review.json",
        f"research/validation-{version}/manifest.json",
    }
    for folder in (*REQUIRED_FOLDERS, f"research/validation-{version}"):
        paths = [path for path in (root / folder).rglob("*")
                 if path.is_file() and not FORBIDDEN_PARTS.intersection(path.relative_to(root).parts)
                 and path.suffix != ".pyc"]
        if not paths:
            raise RuntimeError(f"Required delivery folder missing or empty: {folder}")
        required.update(path.relative_to(root).as_posix() for path in paths)
    missing = sorted(name for name in required if not (root / name).is_file())
    if missing:
        raise RuntimeError("Required workspace files absent: " + ", ".join(missing))
    return required


def verify_validation(root: Path, version: str) -> dict:
    """Refuse to publish a local ZIP with success evidence from different sources."""
    relative = f"research/validation-{version}/manifest.json"
    manifest = json.loads((root / relative).read_text())
    if manifest.get("result") != "pass" or manifest.get("version") != version:
        raise RuntimeError("Current validation manifest has not passed for this version")
    if manifest.get("sources_unchanged_during_run") is not True:
        raise RuntimeError("Validation did not prove product sources stayed unchanged during the run")
    commands = manifest.get("commands", [])
    labels = [command.get("label") for command in commands]
    if len(labels) != len(set(labels)) or REQUIRED_COMMANDS - set(labels):
        raise RuntimeError("Validation manifest omits or repeats required local gates")
    for command in commands:
        if command.get("exit") != 0:
            raise RuntimeError("Validation command failed: " + str(command.get("label")))
        log = str(command.get("log", ""))
        safe_name(log)
        if not (root / relative).parent.joinpath(log).is_file():
            raise RuntimeError("Validation log missing: " + log)
    tests = manifest.get("backend_tests", [])
    if len(tests) != len(BACKENDS) or {test.get("target") for test in tests} != BACKENDS:
        raise RuntimeError("Validation evidence does not cover all four library backends")
    if any(not isinstance(test.get("total"), int) or test["total"] <= 0
           or test.get("passed") != test["total"] or test.get("failed") != 0 for test in tests):
        raise RuntimeError("One or more backend tests did not pass completely")
    actual = {path.relative_to(root).as_posix(): file_digest(path) for path in root.rglob("*")
              if validation_source(path, root)}
    expected = manifest.get("source_sha256", {})
    changed = sorted(name for name in actual.keys() | expected.keys() if actual.get(name) != expected.get(name))
    if changed:
        raise RuntimeError("Validation is stale for product source/configuration(s): " + ", ".join(changed[:12]))
    gate_paths = {*((root / "scripts").rglob("*.py")), root / "scripts/moon-local",
                  root / "research/normative-completion/build_rule_inventory.py"}
    gate_actual = {path.relative_to(root).as_posix(): file_digest(path) for path in sorted(gate_paths)}
    assert_evidence(manifest.get("gate_sources_unchanged_during_run") is True
                    and manifest.get("gate_source_sha256") == gate_actual,
                    "Validation is stale for local validation/package gate scripts")
    fixture_path = root / "fixtures/manifest.json"
    if manifest.get("fixture_manifest_sha256") != file_digest(fixture_path):
        raise RuntimeError("Validation is stale for the fixture manifest")
    if manifest.get("fixture_count") != len(json.loads(fixture_path.read_text())["cases"]):
        raise RuntimeError("Validation fixture count is inconsistent")
    operational_fixture_path = root / "fixtures/commissioning/manifest.json"
    operational_report_path = root / "research/commissioning/manifest.json"
    assert_evidence(manifest.get("operational_fixture_manifest_sha256") == file_digest(operational_fixture_path)
                    and manifest.get("operational_report_sha256") == file_digest(operational_report_path),
                    "Validation is stale for operational fixture/report evidence")
    operational = json.loads(operational_report_path.read_text())
    assert_evidence(operational.get("status") == "pass"
                    and operational.get("sources_unchanged_during_run") is True
                    and operational.get("fixture_manifest_sha256") == file_digest(operational_fixture_path)
                    and operational.get("failures") == [],
                    "Operational fixture/report evidence has not passed against its current inputs")
    return {"manifest": relative, "sha256": file_digest(root / relative), "backend_tests": tests,
            "source_files_verified": len(actual), "gate_source_files_verified": len(gate_actual),
            "fixture_manifest_sha256": file_digest(fixture_path)}



def assert_evidence(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def verify_source_records(root: Path, records: list[dict], context: str) -> None:
    assert_evidence(bool(records), context + " has no source bindings")
    paths = [record.get("path") for record in records]
    assert_evidence(len(paths) == len(set(paths)), context + " repeats source bindings")
    for record in records:
        name = record["path"]
        safe_name(name)
        assert_evidence((root / name).is_file() and file_digest(root / name) == record.get("sha256"),
                        context + " is stale for " + name)


def supplemental_hit_identity(name: str, version: str, archive_sha256: str, hit: dict) -> str:
    payload = {"name": name, "version": version, "zip_sha256": archive_sha256,
               "path": hit["path"], "line": hit["line"], "text": hit.get("text")}
    return digest(json.dumps(payload, ensure_ascii=False, sort_keys=True).encode())


def expected_supplemental_hit_ids(supplement: dict) -> set[str]:
    expected: set[str] = set()
    for archive in supplement.get("archives", []):
        package = (archive["name"], archive["version"], archive["archive_sha256"])
        def add(member: dict, hit: dict) -> None:
            expected.add(supplemental_hit_identity(*package, {"path": member["path"], **hit}))
        for member in archive.get("binary_members", []):
            for hit in member.get("hits", []):
                add(member, hit)
            for hit in member.get("mixed_log_byte_view", {}).get("hits", []):
                add(member, hit)
        for member in archive.get("long_line_text_members", []):
            for hit in member.get("corrected_long_line_hits", []):
                add(member, hit)
        for member in archive.get("source_nul_text_members", []):
            for hit in member.get("strict_utf8_hits", []):
                add(member, hit)
            for hit in member.get("nul_stripped_ascii_byte_probe", {}).get("hits", []):
                add(member, hit)
            for hit in member.get("identified_mixed_readme_tail", {}).get("hits", []):
                add(member, hit)
    return expected


def verify_rule_evidence(root: Path) -> dict:
    directory = root / "research/normative-completion"
    inventory_path = directory / "rule-inventory.json"
    coverage_path = directory / "test-coverage.json"
    inventory = json.loads(inventory_path.read_text())
    coverage = json.loads(coverage_path.read_text())
    assert_evidence(inventory.get("sources_unchanged_during_run") is True,
                    "Rule inventory changed during its run")
    assert_evidence(coverage.get("successful") is True and coverage.get("typed_rule_tests_successful") is True
                    and coverage.get("sources_unchanged_during_run") is True, "Rule coverage has not passed")
    verify_source_records(root, inventory.get("sources", []), "Rule inventory")
    verify_source_records(root, coverage.get("sources", []), "Rule coverage")
    verify_source_records(root, [inventory["generator"]], "Rule inventory generator")
    verify_source_records(root, [coverage["runner"]], "Rule coverage runner")
    for run in inventory.get("actual_cli_runs", []):
        verify_source_records(root, [{"path": run["fixture"], "sha256": run["sha256"]}], "CLI rule fixture")
    referenced = coverage.get("referenced_cli_inventory", {})
    validation = referenced.get("validation", {})
    assert_evidence(referenced.get("established") is True and validation.get("valid") is True
                    and validation.get("unchanged_during_run") is True
                    and referenced.get("sha256") == file_digest(inventory_path),
                    "Rule coverage is not bound to the current CLI inventory")
    implemented = referenced.get("implemented_rule_count")
    assert_evidence(isinstance(implemented, int) and implemented > 0
                    and implemented == inventory.get("rule_count")
                    and implemented == len(inventory.get("rules", []))
                    and referenced.get("cli_or_this_run_observed_rule_count") == implemented
                    and referenced.get("without_either_runtime_evidence") == [],
                    "Not all implemented rule names have current runtime evidence")
    return {"inventory_sha256": file_digest(inventory_path), "coverage_sha256": file_digest(coverage_path),
            "implemented_rule_count": implemented, "runtime_rule_union_count": implemented}


def verify_full_source_evidence(root: Path) -> dict:
    directory = root / "research/full-source-audit"
    manifest_path = directory / "manifest.json"
    manifest = json.loads(manifest_path.read_text())
    modules_path = directory / "modules.json"
    modules = json.loads(modules_path.read_text())
    pairs = [(module["name"], module["version"]) for module in modules]
    count = len(pairs)
    assert_evidence(count > 0 and len(set(pairs)) == count, "Full-source pinned index is empty or duplicated")
    assert_evidence(manifest.get("final") is True, "Full-source audit is not final; no final delivery ZIP can be certified")
    index = manifest.get("index", {})
    assert_evidence(index == json.loads((directory / "index.json").read_text()),
                    "Full-source manifest/index metadata differ")
    assert_evidence(all(value == count for value in [manifest.get("expected_modules"), manifest.get("processed_modules"),
                    manifest.get("expected_unique_name_versions"), index.get("count"), index.get("unique_name_versions")]),
                    "Full-source audit does not cover exactly the pinned index")
    assert_evidence(manifest.get("unresolved") == [] and manifest.get("statuses", {}).get("ok") == count
                    and not any(value for key, value in manifest.get("statuses", {}).items() if key != "ok"),
                    "Full-source audit still has unresolved/limited/error modules")
    assert_evidence(index.get("modules_json_sha256") == file_digest(modules_path)
                    and manifest.get("modules_json_sha256") == file_digest(modules_path), "Full-source modules hash is stale")
    raw_path = safe_name(index.get("raw_body_file", ""))
    raw = directory / str(raw_path)
    assert_evidence(index.get("raw_sha256") == file_digest(raw) and json.loads(raw.read_bytes()) == modules,
                    "Full-source raw index differs from the pinned modules")
    scanner = root / "scripts/audit_all_mooncakes_sources.py"
    assert_evidence(manifest.get("scanner_version", 0) >= 4 and manifest.get("scanner_sha256") == file_digest(scanner),
                    "Full-source scanner source/version is stale")
    assert_evidence(manifest.get("encoding_overrides_sha256") == file_digest(directory / "encoding-overrides.json"),
                    "Full-source encoding configuration is stale")
    bindings = manifest.get("result_bindings", [])
    assert_evidence([(item.get("name"), item.get("version")) for item in bindings] == pairs,
                    "Full-source result bindings do not match pinned index exactly once")
    snapshots = []
    supplementary_archives = {}
    all_result_metadata = {}
    binary_expected = large_text_expected = 0
    for pair, binding in zip(pairs, bindings):
        key = digest((pair[0] + "\0" + pair[1]).encode())
        name = f"results/{key}.json"
        assert_evidence(binding.get("file") == name, "Full-source result path is not canonical")
        path = directory / name
        assert_evidence(binding.get("sha256") == file_digest(path), "Full-source result hash is stale: " + name)
        result = json.loads(path.read_text())
        assert_evidence((result.get("name"), result.get("version")) == pair
                        and result.get("scanner_version") == manifest["scanner_version"]
                        and result.get("scanner_sha256") == manifest["scanner_sha256"]
                        and result.get("status") == "ok" and result.get("limitations") == [],
                        "Full-source result is unresolved or has a different scanner: " + name)
        snapshots.append({"name": pair[0], "version": pair[1], "source_result_file": name,
                          "source_result_sha256": binding["sha256"]})
        all_result_metadata[pair] = {"archive_sha256": result["sha256"], "result_file": name,
                                     "result_sha256": binding["sha256"]}
        files = result.get("files", [])
        binary = [row for row in files if row.get("kind") == "binary"]
        large_text = [row for row in files if row.get("kind") == "text" and row.get("bytes", 0) > 4 * 1024**2]
        assert_evidence(result.get("binary_files") == len(binary), "Full-source binary member count is inconsistent")
        binary_expected += len(binary)
        large_text_expected += len(large_text)
        if binary or large_text:
            supplementary_archives[pair] = {**all_result_metadata[pair], "binary_members": binary,
                "long_line_text_members": large_text, "source_nul_text_members": []}
    verification_path = directory / "verification.json"
    verification = json.loads(verification_path.read_text())
    assert_evidence(verification.get("result") == "pass"
                    and verification.get("manifest_sha256") == file_digest(manifest_path)
                    and verification.get("verifier_sha256") == file_digest(directory / "verify_manifest.py")
                    and verification.get("scanner_sha256") == manifest["scanner_sha256"]
                    and verification.get("scanner_version") == manifest["scanner_version"]
                    and verification.get("index_raw_sha256") == index["raw_sha256"]
                    and verification.get("index_pretty_sha256") == index["modules_json_sha256"]
                    and verification.get("encoding_overrides_sha256") == manifest["encoding_overrides_sha256"]
                    and verification.get("verification_depth") == "archive_and_all_member_sha256"
                    and all(verification.get(key) == count for key in ["expected_modules", "verified_results", "verified_archives"]),
                    "Full-source archive/member verification is missing, incomplete or stale")
    nul_review_path = directory / "text-source-nul-review.json"
    nul_review = json.loads(nul_review_path.read_text())
    recheck_path = directory / "text-source-nul-review-recheck-summary.json"
    recheck = json.loads(recheck_path.read_text())
    assert_evidence(nul_review.get("result") == "pass" and nul_review.get("errors") == []
                    and nul_review.get("changed_result_files") == [] and nul_review.get("not_yet_v4_ok") == []
                    and nul_review.get("completed_results") == nul_review.get("index_modules") == count
                    and nul_review.get("modules_json_sha256") == index["modules_json_sha256"]
                    and nul_review.get("main_scanner_sha256") == manifest["scanner_sha256"]
                    and nul_review.get("main_scanner_version") == manifest["scanner_version"]
                    and nul_review.get("encoding_overrides_sha256") == manifest["encoding_overrides_sha256"],
                    "Text source NUL review is incomplete or stale")
    assert_evidence(recheck.get("schema") == "mooncakes-text-source-nul-review-recheck-summary/v1"
                    and recheck.get("result") == "pass" and recheck.get("script") == "audit_source_nul.py"
                    and recheck.get("script_sha256") == file_digest(directory / "audit_source_nul.py")
                    and recheck.get("frozen_review") == "text-source-nul-review.json"
                    and recheck.get("frozen_review_sha256") == file_digest(nul_review_path)
                    and recheck.get("main_manifest_sha256") == file_digest(manifest_path)
                    and recheck.get("main_scanner_sha256") == manifest["scanner_sha256"]
                    and recheck.get("modules_json_sha256") == index["modules_json_sha256"]
                    and recheck.get("main_scanner_version") == manifest["scanner_version"]
                    and recheck.get("index_modules") == recheck.get("completed_results") == count
                    and recheck.get("errors") == [] and recheck.get("changed_result_files") == []
                    and recheck.get("not_yet_v4_ok") == []
                    and isinstance(recheck.get("recheck_output_sha256"), str)
                    and len(recheck["recheck_output_sha256"]) == 64,
                    "Independent text source NUL recheck is missing or stale")
    nul_archives = nul_review.get("archives", [])
    nul_pairs = [(row["name"], row["version"]) for row in nul_archives]
    assert_evidence(len(nul_pairs) == len(set(nul_pairs)) and set(nul_pairs) == set(pairs)
                    and len(nul_archives) == count,
                    "Text source NUL review does not cover every current package exactly once")
    nul_expected = 0
    for archive in nul_archives:
        pair = (archive["name"], archive["version"])
        expected = all_result_metadata[pair]
        assert_evidence(all(archive.get(key) == expected[key] for key in ["archive_sha256", "result_file", "result_sha256"]),
                        "Text source NUL review result binding is stale")
        if not archive.get("nul_members"):
            continue
        source = json.loads((directory / expected["result_file"]).read_text())
        files = {row["path"]: row for row in source["files"]}
        for member in archive["nul_members"]:
            current = files.get(member["path"], {})
            assert_evidence(current.get("kind") == "text" and current.get("sha256") == member["sha256"],
                            "Text source NUL member differs from current source")
            if member["inventory_encoding"] in {"utf-16", "utf-32"}:
                assert_evidence(member.get("bom") is not None, "Text source NUL UTF-16/32 record lacks BOM evidence")
                continue
            assert_evidence(member.get("strict_decoding_checks", {}).get("utf-8", {}).get("valid") is True
                            and bool(member.get("manual_review")), "Text source NUL member lacks encoding/manual review")
            target = supplementary_archives.setdefault(pair, {**expected, "binary_members": [],
                "long_line_text_members": [], "source_nul_text_members": []})
            target["source_nul_text_members"].append(current)
            nul_expected += 1
    supplement_path = directory / "supplemental-binary-text.json"
    supplement = json.loads(supplement_path.read_text())
    assert_evidence(supplement.get("schema") == "mooncakes-binary-text-supplement/v1"
                    and supplement.get("result") == "pass"
                    and supplement.get("limitations") == [] and supplement.get("unresolved") == []
                    and supplement.get("supplemental_scanner_sha256") == file_digest(directory / "supplemental_binary_text_scan.py")
                    and supplement.get("main_manifest_sha256") == file_digest(manifest_path)
                    and supplement.get("main_scanner_sha256") == manifest["scanner_sha256"]
                    and supplement.get("main_scanner_version") == manifest["scanner_version"]
                    and supplement.get("index_raw_sha256") == index["raw_sha256"]
                    and supplement.get("index_pretty_sha256") == index["modules_json_sha256"]
                    and supplement.get("encoding_overrides_sha256") == manifest["encoding_overrides_sha256"]
                    and supplement.get("source_nul_review_sha256") == file_digest(nul_review_path)
                    and supplement.get("result_bindings") == bindings
                    and supplement.get("keyword_patterns") == manifest.get("keyword_patterns")
                    and all(supplement.get(key) == count for key in ["expected_modules", "verified_result_bindings"])
                    and supplement.get("binary_members_expected") == supplement.get("binary_members_read_and_hashed") == binary_expected
                    and supplement.get("long_line_candidate_files_expected") == supplement.get("long_line_candidate_files_checked") == large_text_expected
                    and supplement.get("source_nul_files_expected") == supplement.get("source_nul_files_checked") == nul_expected,
                    "Supplemental binary/long-line scan is missing, incomplete or stale")
    archives = supplement.get("archives", [])
    assert_evidence(len(archives) == len(supplementary_archives)
                    and {(row["name"], row["version"]) for row in archives} == set(supplementary_archives),
                    "Supplemental archive coverage differs from current source member inventory")
    for archive in archives:
        expected = supplementary_archives[(archive["name"], archive["version"])]
        assert_evidence(all(archive.get(key) == expected[key] for key in ["archive_sha256", "result_file", "result_sha256"]),
                        "Supplemental archive source binding is stale")
        for field in ["binary_members", "long_line_text_members", "source_nul_text_members"]:
            observed = [{key: record.get(key) for key in ["path", "bytes", "sha256"]} for record in archive.get(field, [])]
            wanted = [{key: record[key] for key in ["path", "bytes", "sha256"]} for record in expected[field]]
            assert_evidence(observed == wanted, "Supplemental member coverage/hash is incomplete or stale")
    return {"manifest_sha256": file_digest(manifest_path), "verification_sha256": file_digest(verification_path),
            "supplemental_sha256": file_digest(supplement_path),
            "module_count": count, "manifest": manifest, "pairs": pairs,
            "result_bindings": {"research/full-source-audit/" + binding["file"]: binding["sha256"] for binding in bindings},
            "source_inventory": {"schema": manifest["schema"], "final": True, "expected_modules": count,
                "index_sha256": file_digest(modules_path),
                "result_metadata_snapshot_sha256": digest(json.dumps(snapshots, ensure_ascii=False, sort_keys=True,
                                                        separators=(",", ":")).encode())}}


def verify_review_snapshot(root: Path, snapshot: dict, full: dict, script: str, context: str) -> None:
    assert_evidence(snapshot.get("inventory_sha256") == full["manifest_sha256"]
                    and snapshot.get("modules_sha256") == full["source_inventory"]["index_sha256"]
                    and snapshot.get("join_script_sha256") == file_digest(root / script)
                    and snapshot.get("inputs_unchanged_after_join") is True,
                    context + " is bound to stale input/script or changed during its run")
    sources = snapshot.get("source_results", [])
    actual = {row["path"]: row.get("sha256") for row in sources}
    assert_evidence(len(actual) == len(sources) and actual == full["result_bindings"],
                    context + " source results do not cover the current inventory exactly once")


def verify_originality_evidence(root: Path, full: dict) -> dict:
    directory = root / "research/originality-completion"
    local = {path.relative_to(root).as_posix(): file_digest(path) for path in root.rglob("*.mbt")
             if not SOURCE_EXCLUSIONS.intersection(path.relative_to(root).parts)
             and not path.name.endswith(("_test.mbt", "_wbtest.mbt"))
             and "tests" not in path.relative_to(root).parts}
    reports = {}
    screens = {}
    for level in (40, 80):
        path = directory / f"full-source-clone-screen-{level}.json"
        screen = json.loads(path.read_text())
        assert_evidence(screen.get("audit") == "research/full-source-audit/manifest.json"
                        and screen.get("audit_sha256") == full["manifest_sha256"]
                        and screen.get("source_inventory") == full["source_inventory"],
                        "Full clone screen is not bound to the current full inventory")
        actual = {row["path"]: row["sha256"] for row in screen.get("local_sources", [])}
        assert_evidence(len(actual) == len(screen.get("local_sources", [])) and actual == local,
                        "Full clone screen is stale for local product source")
        assert_evidence(screen.get("detector_sha256") == file_digest(root / "scripts/verify_source_originality.py"),
                        "Full clone detector source is stale")
        method = screen.get("method", {})
        parallel = screen.get("parallel_method", {})
        assert_evidence(method.get("minimum_tokens") == level
                        and method.get("minimum_local_source_span_lines") == (5 if level == 40 else 8)
                        and method.get("include_generated") is True and method.get("include_foreign_tests") is True
                        and method.get("third_party_code_executed") is False
                        and parallel.get("runner_sha256") == file_digest(root / "scripts/run_source_originality_full.py")
                        and all(parallel.get(key) is True for key in ["local_code_frozen_and_verified_after_merge",
                            "package_coverage_exactly_once", "source_result_metadata_snapshot_verified_after_merge",
                            "all_scanned_archive_hashes_verified_after_merge"])
                        and screen.get("shard", {}).get("coverage_verified_exactly_once") is True,
                        "Full clone screen lacks inclusive/frozen complete-scan evidence")
        summary = screen.get("summary", {})
        packages = screen.get("packages", [])
        assert_evidence(len(packages) == full["module_count"]
                        and {(item["name"], item["version"]) for item in packages} == set(full["pairs"])
                        and all(summary.get(key) == full["module_count"] for key in ["packages", "expected_packages"])
                        and summary.get("unresolved_packages") == 0 and summary.get("limited_source_inventories") == 0
                        and screen.get("unresolved_packages") == [] and screen.get("source_inventory_limitations") == [],
                        "Full clone screen does not cover every current package")
        for item in packages:
            source_path = item.get("source_result_file", "")
            safe_name(source_path)
            key = digest((item["name"] + "\0" + item["version"]).encode())
            assert_evidence(source_path == f"results/{key}.json"
                            and item.get("source_result_sha256") == full["result_bindings"].get("research/full-source-audit/" + source_path),
                            "Full clone result binding is stale")
        candidates = screen.get("candidate_matches", [])
        assert_evidence(summary.get("candidate_matches") == len(candidates), "Full clone candidate count is inconsistent")
        reports[level] = {"sha256": file_digest(path), "candidate_matches": len(candidates)}
        screens[level] = screen
    derivation = screens[80].get("derivation", {})
    strict = [row for row in screens[40]["candidate_matches"] if row["tokens"] >= 80
              and row["local_lines"][1] - row["local_lines"][0] + 1 >= 8
              and (row["kind"] == "exact_tokens" or (row["kind"] == "consistent_identifier_rename_block"
                   and row["external_lines"][1] - row["external_lines"][0] + 1 >= 8))]
    assert_evidence(derivation.get("from") == "full-source-clone-screen-40.json"
                    and derivation.get("source_sha256") == reports[40]["sha256"]
                    and screens[80]["candidate_matches"] == strict,
                    "Strict clone report is not the complete bound threshold subset")
    if reports[40]["candidate_matches"]:
        human_path = directory / "full-source-clone-human-review.json"
        human = json.loads(human_path.read_text())
        source = human.get("source_screen", {})
        reviews = human.get("candidate_reviews", [])
        assert_evidence(source.get("sha256") == reports[40]["sha256"] and human.get("pending_manual_review") == 0
                        and human.get("reviewed_candidate_count") == reports[40]["candidate_matches"]
                        and sorted(row.get("candidate_index") for row in reviews) == list(range(reports[40]["candidate_matches"]))
                        and all(row.get("disposition") in {"common_standard_fragment", "independent_implementation", "attributed_reuse", "remediated"}
                                and row.get("reason") for row in reviews), "Full clone candidates still need bound human review")
    semantic_path = directory / "full-source-semantic-review.json"
    semantic = json.loads(semantic_path.read_text())
    snapshot = semantic.get("snapshot", {})
    assert_evidence(semantic.get("complete_current_inventory") is True and semantic.get("pending") == []
                    and semantic.get("summary", {}).get("pending_manual_review") == 0,
                    "Full semantic review is pending or bound to an older inventory")
    verify_review_snapshot(root, snapshot, full, "scripts/review_source_semantic_hits.py", "Semantic review")
    assert_evidence(snapshot.get("manual_reviews_sha256") == file_digest(directory / "manual-semantic-dispositions.json"),
                    "Semantic manual dispositions changed after joining")
    neighbor_path = directory / "final-neighbor-review-coverage.json"
    neighbor = json.loads(neighbor_path.read_text())
    assert_evidence(neighbor.get("complete_current_inventory") is True
                    and neighbor.get("complete_saved_hit_context_reviews") is True and neighbor.get("pending") == [],
                    "Neighbor context review still has unreviewed current hits")
    neighbor_snapshot = neighbor.get("snapshot", {})
    verify_review_snapshot(root, neighbor_snapshot, full, "scripts/verify_neighbor_reviews.py", "Neighbor context review")
    manual_reports = neighbor_snapshot.get("review_reports", [])
    assert_evidence({row["path"] for row in manual_reports} == {
        "research/originality-completion/clock-neighbor-context-review.json",
        "research/originality-completion/association-neighbor-context-review.json"} and len(manual_reports) == 2,
        "Neighbor context review omits a required manual report")
    verify_source_records(root, manual_reports, "Neighbor manual reports")
    supplemental_review_path = directory / "supplemental-source-semantic-review.json"
    supplemental_review = json.loads(supplemental_review_path.read_text())
    supplemental_snapshot = supplemental_review.get("snapshot", {})
    assert_evidence(supplemental_review.get("complete") is True and supplemental_review.get("pending") == []
                    and supplemental_review.get("summary", {}).get("pending_manual_review") == 0
                    and supplemental_snapshot.get("supplemental_sha256") == full["supplemental_sha256"]
                    and supplemental_snapshot.get("main_manifest_sha256") == full["manifest_sha256"]
                    and supplemental_snapshot.get("supplemental_path") == "research/full-source-audit/supplemental-binary-text.json"
                    and supplemental_snapshot.get("join_script_sha256") == file_digest(root / "scripts/review_supplemental_semantic_hits.py")
                    and supplemental_snapshot.get("source_nul_review_sha256") == file_digest(root / "research/full-source-audit/text-source-nul-review.json")
                    and supplemental_snapshot.get("identity_script") == {
                        "path": "scripts/review_source_semantic_hits.py",
                        "sha256": file_digest(root / "scripts/review_source_semantic_hits.py")}
                    and supplemental_snapshot.get("inputs_unchanged_after_join") is True,
                    "Supplemental semantic review is pending, incomplete or stale")
    ledger_records = supplemental_snapshot.get("manual_ledgers", [])
    assert_evidence({record.get("path") for record in ledger_records} == {
        "research/originality-completion/manual-semantic-dispositions.json",
        "research/originality-completion/supplemental-manual-dispositions.json"}
                    and len(ledger_records) == 2,
                    "Supplemental semantic review omits a required manual ledger")
    verify_source_records(root, ledger_records, "Supplemental semantic ledgers")
    supplement = json.loads((root / "research/full-source-audit/supplemental-binary-text.json").read_text())
    expected_hits = expected_supplemental_hit_ids(supplement)
    reviewed_hits = {row.get("source_hit_id") for row in supplemental_review.get("reviews", [])}
    assert_evidence(None not in reviewed_hits and len(reviewed_hits) == len(supplemental_review.get("reviews", []))
                    and reviewed_hits == expected_hits
                    and supplemental_review.get("summary", {}).get("all_keyword_hit_records") == len(expected_hits)
                    and supplemental_review.get("summary", {}).get("manually_reviewed_records") == len(expected_hits),
                    "Supplemental semantic review does not cover every current supplemental hit")
    return {"clone_reports": reports, "semantic_review_sha256": file_digest(semantic_path),
            "neighbor_review_sha256": file_digest(neighbor_path),
            "supplemental_semantic_review_sha256": file_digest(supplemental_review_path),
            "boundary": "Current pinned source coverage and reviewed candidates; not absolute semantic non-similarity certification"}


def verify_archive(package: zipfile.ZipFile, root: Path, required: set[str]) -> dict:
    infos = package.infolist()
    names = [entry.filename for entry in infos]
    if len(names) != len(set(names)):
        raise RuntimeError("Duplicate ZIP entry names")
    normalized = set()
    total = 0
    checked = {}
    for entry in infos:
        path = safe_name(entry.filename)
        key = str(path)
        if key in normalized:
            raise RuntimeError("ZIP file/directory name collision: " + key)
        normalized.add(key)
        if FORBIDDEN_PARTS.intersection(path.parts):
            raise RuntimeError("Unexpected cache/toolchain content: " + key)
        if key in FORBIDDEN_FILES:
            raise RuntimeError("Withdrawn third-party capture in delivery: " + key)
        kind = stat.S_IFMT(entry.external_attr >> 16)
        if kind not in {0, stat.S_IFREG, stat.S_IFDIR}:
            raise RuntimeError("ZIP special/symlink entry: " + key)
        if entry.flag_bits & 1:
            raise RuntimeError("Encrypted ZIP entry: " + key)
        if entry.is_dir():
            if not (root / key).is_dir():
                raise RuntimeError("ZIP directory absent from workspace: " + key)
            continue
        if kind == stat.S_IFDIR:
            raise RuntimeError("Directory type used for ZIP file: " + key)
        total += entry.file_size
        if entry.file_size > 256 * 1024**2 or total > 1024**3:
            raise RuntimeError("ZIP delivery size limit exceeded")
        source = root / key
        if not source.is_file():
            raise RuntimeError("ZIP file absent from workspace: " + key)
        data = package.read(entry)
        if data != source.read_bytes():
            raise RuntimeError("ZIP differs from saved workspace file: " + key)
        if key in EXECUTABLES and not ((entry.external_attr >> 16) & 0o111):
            raise RuntimeError("Executable mode absent from ZIP entry: " + key)
        checked[key] = digest(data)
    missing = sorted(required - set(checked))
    if missing:
        raise RuntimeError("Required files absent from ZIP: " + ", ".join(missing[:20]))
    if package.testzip() is not None:
        raise RuntimeError("ZIP CRC failed")
    return {"entries": len(infos), "required_files_verified": len(required),
            "all_included_files_match_workspace": True, "raw_third_party_caches_excluded": True,
            "entry_sha256": checked}


def main() -> int:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    text = (ROOT / "moon.mod").read_text()
    name_match = re.search(r'^name\s*=\s*"([^\"]+)"', text, re.M)
    version_match = re.search(r'^version\s*=\s*"([^\"]+)"', text, re.M)
    if not name_match or not version_match:
        raise RuntimeError("moon.mod must declare name and version")
    name, version = name_match.group(1), version_match.group(1)
    if not re.fullmatch(r"[A-Za-z0-9._-]+/[A-Za-z0-9._-]+", name) or not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+(?:[-+][A-Za-z0-9.-]+)?", version):
        raise RuntimeError("Unsupported local archive name/version")
    archive = OUTPUT / f"{name.replace('/', '-')}-{version}.zip"
    report = {"scope": "local ZIP only; no registry publication", "archive": archive.name,
              "version": version, "result": "fail", "smoke_tests": []}
    try:
        report["validation_evidence"] = verify_validation(ROOT, version)
        proposal = ROOT / "output/pdf/ptp-audit-项目申报书.pdf"
        proposal_info = json.loads(proposal.with_suffix(".verification.json").read_text())
        assert_evidence(proposal_info.get("source_sha256") == file_digest(ROOT / "PROJECT_APPLICATION.md")
                        and proposal_info.get("pdf_sha256") == file_digest(proposal)
                        and proposal_info.get("pages") == 1,
                        "One-page proposal does not match its current source/PDF")
        report["proposal"] = {"pages": 1, "pdf_sha256": file_digest(proposal),
                              "source_sha256": proposal_info["source_sha256"]}
        report["rule_evidence"] = verify_rule_evidence(ROOT)
        full = verify_full_source_evidence(ROOT)
        report["full_source_evidence"] = {key: full[key] for key in ["manifest_sha256", "verification_sha256", "supplemental_sha256", "module_count"]}
        report["originality_evidence"] = verify_originality_evidence(ROOT, full)
        required = required_files(ROOT, version)
        before = {path: file_digest(ROOT / path) for path in sorted(required)}
        result = subprocess.run(["scripts/moon-local", "package"], cwd=ROOT, text=True, capture_output=True, timeout=180)
        (OUTPUT / "package.log").write_text(result.stdout + result.stderr)
        if result.returncode:
            raise RuntimeError("moon package failed; see _build/publish/package.log")
        after = {path: file_digest(ROOT / path) for path in sorted(required)}
        if before != after or required_files(ROOT, version) != required:
            raise RuntimeError("Workspace evidence changed during packaging; wait for scanners/edits to finish")
        repository = re.search(r'^repository\s*=\s*"([^\"]*)"', text, re.M)
        report["repository_metadata"] = repository.group(1) if repository else None
        report["repository_notice"] = "metadata only; local package does not imply source push, registry publication, or contest submission"
        with zipfile.ZipFile(archive) as package:
            report.update(verify_archive(package, ROOT, required))
            full = json.loads((ROOT / "research/full-source-audit/manifest.json").read_text())
            report["full_source_audit_state"] = {key: full.get(key) for key in ["final", "expected_modules", "processed_modules", "statuses", "unresolved"]}
            report["normative_source_state"] = {"complete_normative_text_obtained": json.loads((ROOT / "research/normative-completion/source-access.json").read_text()).get("complete_normative_text_obtained")}
            with tempfile.TemporaryDirectory(prefix="ptp-audit-delivery-") as directory:
                extracted = Path(directory)
                # Every member was validated before writing anything to disk.
                for entry in package.infolist():
                    destination = Path(package.extract(entry, extracted))
                    mode = (entry.external_attr >> 16) & 0o777
                    if mode and destination.is_file():
                        destination.chmod(mode)
                cases = [
                    ("native-from-clean-extracted-package", ["scripts/moon-local", "test", "--target", "native", "--deny-warn"], 0, None),
                    ("complete-cli-from-clean-package", ["bin/ptp-audit.mjs", "check", "fixtures/complete-audit.json", "--json"], 0, "Pass"),
                    ("missing-epoch-cli-from-package", ["bin/ptp-audit.mjs", "check", "fixtures/missing-all-epoch.json", "--json"], 3, "InsufficientEvidence"),
                    ("mixed-bmca-epoch-cli-from-package", ["bin/ptp-audit.mjs", "check", "fixtures/bmca-mixed-epoch.json", "--json"], 3, "InsufficientEvidence"),
                    ("commissioning-from-clean-package", ["bin/ptp-audit.mjs", "commission", "fixtures/commissioning/grandmaster-switch.json", "--json"], 0, "Pass"),
                    ("old-master-rejected-from-package", ["bin/ptp-audit.mjs", "commission", "fixtures/commissioning/old-master-after-switch.json", "--json"], 1, "Violation"),
                    ("ptp-budget-from-clean-package", ["bin/ptp-audit.mjs", "check", "fixtures/commissioning/metrology-within-limit.json", "--json"], 0, "Pass"),
                ]
                for label, command, expected, status in cases:
                    result = subprocess.run(command, cwd=extracted, text=True, capture_output=True, timeout=600)
                    output = result.stdout + result.stderr
                    (OUTPUT / f"{label}.log").write_text(output)
                    actual = json.loads(result.stdout).get("status") if status is not None else None
                    passed = result.returncode == expected and actual == status
                    report["smoke_tests"].append({"name": label, "command": command, "exit": result.returncode,
                        "expected_exit": expected, "status": actual, "expected_status": status, "pass": passed,
                        "log_sha256": digest(output.encode())})
                    if not passed:
                        raise RuntimeError(label + " failed")
        report.update(result="pass", archive_sha256=file_digest(archive), archive_bytes=archive.stat().st_size)
    except (OSError, RuntimeError, ValueError, KeyError, TypeError, subprocess.TimeoutExpired, zipfile.BadZipFile) as exception:
        report["error"] = str(exception)
    (OUTPUT / f"package-audit-{version}.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n")
    print(json.dumps({key: report.get(key) for key in ["result", "archive", "archive_bytes", "archive_sha256", "error"]}, ensure_ascii=False))
    return 0 if report["result"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
