#!/usr/bin/env python3
"""Offline regression tests for delivery evidence and ZIP extraction preconditions."""
from __future__ import annotations

import importlib.util
import io
import json
from pathlib import Path
import stat
import tempfile
import unittest
import warnings
import zipfile

spec = importlib.util.spec_from_file_location("package_local", Path(__file__).with_name("package_local.py"))
package_local = importlib.util.module_from_spec(spec)
spec.loader.exec_module(package_local)


def make_zip(entries):
    data = io.BytesIO()
    with zipfile.ZipFile(data, "w") as package:
        for name, value, mode in entries:
            entry = zipfile.ZipInfo(name)
            entry.external_attr = mode << 16
            with warnings.catch_warnings():
                warnings.simplefilter("ignore", UserWarning)
                package.writestr(entry, value)
    data.seek(0)
    return zipfile.ZipFile(data)


class DeliveryArchiveTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="package-audit-test-")
        self.root = Path(self.temp.name)
        (self.root / "source.mbt").write_text("pub fn identity(x : Int) -> Int { x }\n")

    def tearDown(self):
        self.temp.cleanup()

    def test_unchanged_regular_delivery_is_verified(self):
        contents = (self.root / "source.mbt").read_bytes()
        with make_zip([("source.mbt", contents, stat.S_IFREG | 0o644)]) as package:
            result = package_local.verify_archive(package, self.root, {"source.mbt"})
        self.assertEqual(result["required_files_verified"], 1)
        self.assertEqual(result["entry_sha256"]["source.mbt"], package_local.digest(contents))

    def test_untrusted_member_paths_are_rejected_before_extraction(self):
        for name in ["../escape", "/absolute", "C:/drive", "folder\\escape", "a/../escape", "a//b", "./source.mbt", ""]:
            with self.subTest(name=name), self.assertRaisesRegex(RuntimeError, "Unsafe/noncanonical"):
                package_local.safe_name(name)

    def test_duplicate_or_file_directory_collision_is_rejected(self):
        for entries in [
            [("source.mbt", b"one", stat.S_IFREG), ("source.mbt", b"two", stat.S_IFREG)],
            [("source.mbt", b"one", stat.S_IFREG), ("source.mbt/", b"", stat.S_IFDIR)],
        ]:
            with make_zip(entries) as package, self.assertRaises(RuntimeError):
                package_local.verify_archive(package, self.root, set())

    def test_withdrawn_capture_is_rejected_even_if_workspace_bytes_match(self):
        path = self.root / "research/wireshark/ptpv2.pcap"
        path.parent.mkdir(parents=True)
        path.write_bytes(b"historical external sample")
        with make_zip([("research/wireshark/ptpv2.pcap", path.read_bytes(), stat.S_IFREG)]) as package:
            with self.assertRaisesRegex(RuntimeError, "Withdrawn third-party capture"):
                package_local.verify_archive(package, self.root, set())

    def test_symlink_or_fifo_cannot_be_extracted_as_delivery(self):
        for mode in [stat.S_IFLNK | 0o777, stat.S_IFIFO | 0o644]:
            with make_zip([("source.mbt", b"destination", mode)]) as package, self.assertRaisesRegex(RuntimeError, "special/symlink"):
                package_local.verify_archive(package, self.root, set())

    def test_orphan_or_mutated_file_cannot_claim_workspace_match(self):
        for name, data, message in [("orphan", b"secret", "absent from workspace"), ("source.mbt", b"old source", "differs from saved")]:
            with make_zip([(name, data, stat.S_IFREG | 0o644)]) as package, self.assertRaisesRegex(RuntimeError, message):
                package_local.verify_archive(package, self.root, set())

    def test_missing_new_evidence_and_lost_entrypoint_mode_fail(self):
        source = (self.root / "source.mbt").read_bytes()
        with make_zip([("source.mbt", source, stat.S_IFREG | 0o644)]) as package, self.assertRaisesRegex(RuntimeError, "Required files absent"):
            package_local.verify_archive(package, self.root, {"research/normative-completion/test-coverage.json"})
        (self.root / "bin").mkdir()
        (self.root / "bin/ptp-audit.mjs").write_bytes(b"#!/usr/bin/env node\n")
        with make_zip([("bin/ptp-audit.mjs", b"#!/usr/bin/env node\n", stat.S_IFREG | 0o644)]) as package, self.assertRaisesRegex(RuntimeError, "Executable mode"):
            package_local.verify_archive(package, self.root, set())


class ValidationBindingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="package-validation-test-")
        self.root = Path(self.temp.name)
        (self.root / "wire").mkdir()
        (self.root / "wire/wire.mbt").write_text("pub fn answer() -> Int { 42 }\n")
        (self.root / "fixtures").mkdir()
        (self.root / "fixtures/manifest.json").write_text('{"cases": [{"path": "one.json"}]}\n')
        (self.root / "fixtures/commissioning").mkdir()
        (self.root / "fixtures/commissioning/manifest.json").write_text('{"cases": []}\n')
        (self.root / "research/commissioning").mkdir(parents=True)
        (self.root / "research/commissioning/manifest.json").write_text(json.dumps({
            "status": "pass", "sources_unchanged_during_run": True, "failures": [],
            "fixture_manifest_sha256": package_local.file_digest(self.root / "fixtures/commissioning/manifest.json")}))
        (self.root / "scripts").mkdir()
        (self.root / "scripts/moon-local").write_text("#!/bin/sh\n")
        builder = self.root / "research/normative-completion/build_rule_inventory.py"
        builder.parent.mkdir(parents=True)
        builder.write_text("# immutable builder\n")
        self.directory = self.root / "research/validation-0.3.0"
        self.directory.mkdir(parents=True)
        commands = []
        for label in sorted(package_local.REQUIRED_COMMANDS):
            (self.directory / (label + ".log")).write_text("pass\n")
            commands.append({"label": label, "exit": 0, "log": label + ".log"})
        self.manifest = {"version": "0.3.0", "result": "pass", "commands": commands,
            "backend_tests": [{"target": backend, "total": 3, "passed": 3, "failed": 0} for backend in package_local.BACKENDS],
            "source_sha256": {"wire/wire.mbt": package_local.file_digest(self.root / "wire/wire.mbt")},
            "sources_unchanged_during_run": True,
            "gate_source_sha256": {name: package_local.file_digest(self.root / name) for name in [
                "scripts/moon-local", "research/normative-completion/build_rule_inventory.py"]},
            "gate_sources_unchanged_during_run": True,
            "fixture_manifest_sha256": package_local.file_digest(self.root / "fixtures/manifest.json"), "fixture_count": 1,
            "operational_fixture_manifest_sha256": package_local.file_digest(self.root / "fixtures/commissioning/manifest.json"),
            "operational_report_sha256": package_local.file_digest(self.root / "research/commissioning/manifest.json")}
        self.save()

    def save(self):
        (self.directory / "manifest.json").write_text(json.dumps(self.manifest))

    def tearDown(self):
        self.temp.cleanup()

    def test_current_successful_evidence_is_bound(self):
        result = package_local.verify_validation(self.root, "0.3.0")
        self.assertEqual(result["source_files_verified"], 1)

    def test_changed_operational_evidence_cannot_reuse_success(self):
        (self.root / "research/commissioning/manifest.json").write_text('{"result": "changed"}\n')
        with self.assertRaisesRegex(RuntimeError, "stale for operational"):
            package_local.verify_validation(self.root, "0.3.0")

    def test_changed_added_and_removed_source_cannot_reuse_success(self):
        (self.root / "wire/new.mbt").write_text("pub fn extra() -> Int { 7 }\n")
        with self.assertRaisesRegex(RuntimeError, "stale.*source"):
            package_local.verify_validation(self.root, "0.3.0")
        (self.root / "wire/new.mbt").unlink()
        (self.root / "wire/wire.mbt").write_text("pub fn answer() -> Int { 43 }\n")
        with self.assertRaisesRegex(RuntimeError, "stale.*source"):
            package_local.verify_validation(self.root, "0.3.0")
        (self.root / "wire/wire.mbt").unlink()
        with self.assertRaisesRegex(RuntimeError, "stale.*source"):
            package_local.verify_validation(self.root, "0.3.0")

    def test_missing_backend_or_failed_gate_is_rejected(self):
        self.manifest["backend_tests"].pop()
        self.save()
        with self.assertRaisesRegex(RuntimeError, "four library backends"):
            package_local.verify_validation(self.root, "0.3.0")
        self.manifest["backend_tests"] = [{"target": b, "total": 3, "passed": 3, "failed": 0} for b in package_local.BACKENDS]
        self.manifest["commands"][0]["exit"] = 1
        self.save()
        with self.assertRaisesRegex(RuntimeError, "command failed"):
            package_local.verify_validation(self.root, "0.3.0")

    def test_missing_gate_or_missing_log_is_rejected(self):
        (self.directory / self.manifest["commands"][0]["log"]).unlink()
        with self.assertRaisesRegex(RuntimeError, "log missing"):
            package_local.verify_validation(self.root, "0.3.0")
        self.manifest["commands"].pop()
        self.save()
        with self.assertRaisesRegex(RuntimeError, "omits or repeats"):
            package_local.verify_validation(self.root, "0.3.0")

    def test_validation_without_source_freeze_marker_is_rejected(self):
        self.manifest["sources_unchanged_during_run"] = False
        self.save()
        with self.assertRaisesRegex(RuntimeError, "sources stayed unchanged"):
            package_local.verify_validation(self.root, "0.3.0")


    def test_new_or_changed_js_and_moon_configuration_invalidates_validation(self):
        for name in ["bin/ptp-audit.mjs", "moon.mod", "wire/moon.pkg"]:
            with self.subTest(name=name):
                path = self.root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("initial\n")
                with self.assertRaisesRegex(RuntimeError, "stale.*configuration"):
                    package_local.verify_validation(self.root, "0.3.0")
                self.manifest["source_sha256"][name] = package_local.file_digest(path)
                self.save()
                package_local.verify_validation(self.root, "0.3.0")
                path.write_text("changed\n")
                with self.assertRaisesRegex(RuntimeError, "stale.*configuration"):
                    package_local.verify_validation(self.root, "0.3.0")
                self.manifest["source_sha256"].pop(name)
                path.unlink()
                self.save()

    def test_new_or_changed_gate_script_invalidates_validation(self):
        path = self.root / "scripts/package_local.py"
        path.write_text("# new gate\n")
        with self.assertRaisesRegex(RuntimeError, "stale.*gate scripts"):
            package_local.verify_validation(self.root, "0.3.0")
        self.manifest["gate_source_sha256"]["scripts/package_local.py"] = package_local.file_digest(path)
        self.save()
        package_local.verify_validation(self.root, "0.3.0")
        path.write_text("# changed gate\n")
        with self.assertRaisesRegex(RuntimeError, "stale.*gate scripts"):
            package_local.verify_validation(self.root, "0.3.0")


class ResearchEvidenceTests(unittest.TestCase):
    """Synthetic one-package research snapshots exercise stale/partial guards."""

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="package-evidence-test-")
        self.root = Path(self.temp.name)
        self.write("wire/wire.mbt", "pub fn answer() -> Int { 42 }\n")
        for name in ["scripts/audit_all_mooncakes_sources.py", "scripts/verify_source_originality.py",
                     "scripts/run_source_originality_full.py", "scripts/review_source_semantic_hits.py",
                     "scripts/review_supplemental_semantic_hits.py",
                     "scripts/verify_neighbor_reviews.py", "scripts/verify_rule_coverage.py",
                     "research/full-source-audit/verify_manifest.py",
                     "research/full-source-audit/audit_source_nul.py",
                     "research/full-source-audit/supplemental_binary_text_scan.py",
                     "research/normative-completion/build_rule_inventory.py"]:
            self.write(name, "# synthetic immutable tool\n")

    def tearDown(self):
        self.temp.cleanup()

    def write(self, name, content):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        return path

    def save(self, name, value):
        return self.write(name, json.dumps(value, sort_keys=True) + "\n")

    def sha(self, name):
        return package_local.file_digest(self.root / name)

    def record(self, name):
        return {"path": name, "sha256": self.sha(name)}

    def rules(self):
        inventory_name = "research/normative-completion/rule-inventory.json"
        self.write("fixtures/one.json", "{}\n")
        inventory = {"sources_unchanged_during_run": True,
            "sources": [self.record("wire/wire.mbt")],
            "generator": self.record("research/normative-completion/build_rule_inventory.py"),
            "rule_count": 1, "rules": [{"rule": "WIRE.EXAMPLE"}],
            "actual_cli_runs": [{"fixture": "fixtures/one.json", "sha256": self.sha("fixtures/one.json")}]}
        self.save(inventory_name, inventory)
        coverage = {"successful": True, "typed_rule_tests_successful": True, "sources_unchanged_during_run": True,
            "sources": [self.record("wire/wire.mbt")], "runner": self.record("scripts/verify_rule_coverage.py"),
            "referenced_cli_inventory": {"established": True, "sha256": self.sha(inventory_name),
                "validation": {"valid": True, "unchanged_during_run": True},
                "implemented_rule_count": 1, "cli_or_this_run_observed_rule_count": 1,
                "without_either_runtime_evidence": []}}
        self.save("research/normative-completion/test-coverage.json", coverage)
        return inventory, coverage

    def full(self):
        self.modules = [{"name": "one/module", "version": "1.0.0"}]
        self.save("research/full-source-audit/modules.json", self.modules)
        self.save("research/full-source-audit/modules-response.raw.json", self.modules)
        self.save("research/full-source-audit/encoding-overrides.json", {"overrides": {}})
        self.index = {"raw_body_file": "modules-response.raw.json", "count": 1, "unique_name_versions": 1,
            "raw_sha256": self.sha("research/full-source-audit/modules-response.raw.json"),
            "modules_json_sha256": self.sha("research/full-source-audit/modules.json")}
        self.save("research/full-source-audit/index.json", self.index)
        result_name = "results/" + package_local.digest(b"one/module\0" + b"1.0.0") + ".json"
        self.result_name = "research/full-source-audit/" + result_name
        self.result = {"name": "one/module", "version": "1.0.0", "scanner_version": 4,
            "scanner_sha256": self.sha("scripts/audit_all_mooncakes_sources.py"), "status": "ok", "limitations": [],
            "files": [], "binary_files": 0, "sha256": "1" * 64}
        self.save(self.result_name, self.result)
        self.full_manifest = {"schema": "mooncakes-full-source-scan/v1", "final": True,
            "expected_modules": 1, "processed_modules": 1, "expected_unique_name_versions": 1,
            "statuses": {"ok": 1}, "unresolved": [], "index": self.index,
            "modules_json_sha256": self.index["modules_json_sha256"], "scanner_version": 4,
            "scanner_sha256": self.result["scanner_sha256"],
            "encoding_overrides_sha256": self.sha("research/full-source-audit/encoding-overrides.json"),
            "result_bindings": [{"name": "one/module", "version": "1.0.0", "file": result_name,
                "sha256": self.sha(self.result_name)}]}
        self.save_full()
        self.verification = {"result": "pass", "manifest_sha256": self.sha("research/full-source-audit/manifest.json"),
            "verifier_sha256": self.sha("research/full-source-audit/verify_manifest.py"),
            "scanner_sha256": self.result["scanner_sha256"], "scanner_version": 4,
            "index_raw_sha256": self.index["raw_sha256"], "index_pretty_sha256": self.index["modules_json_sha256"],
            "encoding_overrides_sha256": self.full_manifest["encoding_overrides_sha256"],
            "verification_depth": "archive_and_all_member_sha256", "expected_modules": 1,
            "verified_results": 1, "verified_archives": 1}
        self.save("research/full-source-audit/verification.json", self.verification)
        self.nul_review = {"result": "pass", "errors": [], "changed_result_files": [], "not_yet_v4_ok": [],
            "completed_results": 1, "index_modules": 1, "modules_json_sha256": self.index["modules_json_sha256"],
            "main_scanner_sha256": self.result["scanner_sha256"], "main_scanner_version": 4,
            "encoding_overrides_sha256": self.full_manifest["encoding_overrides_sha256"],
            "archives": [{"name": "one/module", "version": "1.0.0", "result_file": self.result_name.removeprefix("research/full-source-audit/"),
                "result_sha256": self.sha(self.result_name), "archive_sha256": self.result["sha256"], "nul_members": []}]}
        self.save("research/full-source-audit/text-source-nul-review.json", self.nul_review)
        self.recheck = {"schema": "mooncakes-text-source-nul-review-recheck-summary/v1", "result": "pass",
            "script": "audit_source_nul.py", "script_sha256": self.sha("research/full-source-audit/audit_source_nul.py"),
            "frozen_review": "text-source-nul-review.json", "frozen_review_sha256": self.sha("research/full-source-audit/text-source-nul-review.json"),
            "main_manifest_sha256": self.sha("research/full-source-audit/manifest.json"),
            "main_scanner_sha256": self.result["scanner_sha256"], "modules_json_sha256": self.index["modules_json_sha256"],
            "main_scanner_version": 4, "index_modules": 1, "completed_results": 1,
            "errors": [], "changed_result_files": [], "not_yet_v4_ok": [], "recheck_output_sha256": "2" * 64}
        self.save("research/full-source-audit/text-source-nul-review-recheck-summary.json", self.recheck)
        # The production evidence gate requires an independent recheck summary
        # bound to the frozen NUL review, manifest, scanner and index. Keep the
        # synthetic one-package fixture complete so these regression tests reach
        # the specific stale/partial assertions they are intended to exercise.
        self.recheck = {
            "schema": "mooncakes-text-source-nul-review-recheck-summary/v1",
            "result": "pass",
            "script": "audit_source_nul.py",
            "script_sha256": self.sha("research/full-source-audit/audit_source_nul.py")
            if (self.root / "research/full-source-audit/audit_source_nul.py").exists()
            else "0" * 64,
            "frozen_review": "text-source-nul-review.json",
            "frozen_review_sha256": self.sha("research/full-source-audit/text-source-nul-review.json"),
            "main_manifest_sha256": self.sha("research/full-source-audit/manifest.json"),
            "main_scanner_sha256": self.result["scanner_sha256"],
            "modules_json_sha256": self.index["modules_json_sha256"],
            "main_scanner_version": 4,
            "index_modules": 1,
            "completed_results": 1,
            "errors": [],
            "changed_result_files": [],
            "not_yet_v4_ok": [],
            "recheck_output_sha256": "0" * 64,
        }
        self.save("research/full-source-audit/text-source-nul-review-recheck-summary.json", self.recheck)
        self.supplement = {"schema": "mooncakes-binary-text-supplement/v1", "result": "pass",
            "limitations": [], "unresolved": [],
            "supplemental_scanner_sha256": self.sha("research/full-source-audit/supplemental_binary_text_scan.py"),
            "main_manifest_sha256": self.sha("research/full-source-audit/manifest.json"),
            "main_scanner_sha256": self.result["scanner_sha256"], "main_scanner_version": 4,
            "index_raw_sha256": self.index["raw_sha256"], "index_pretty_sha256": self.index["modules_json_sha256"],
            "encoding_overrides_sha256": self.full_manifest["encoding_overrides_sha256"],
            "source_nul_review_sha256": self.sha("research/full-source-audit/text-source-nul-review.json"),
            "expected_modules": 1, "verified_result_bindings": 1,
            "binary_members_expected": 0, "binary_members_read_and_hashed": 0,
            "long_line_candidate_files_expected": 0, "long_line_candidate_files_checked": 0,
            "source_nul_files_expected": 0, "source_nul_files_checked": 0,
            "result_bindings": self.full_manifest["result_bindings"], "archives": []}
        self.save("research/full-source-audit/supplemental-binary-text.json", self.supplement)
        return package_local.verify_full_source_evidence(self.root)

    def save_full(self):
        self.save("research/full-source-audit/manifest.json", self.full_manifest)

    def originality(self, full):
        source = self.record("wire/wire.mbt")
        package = {"name": "one/module", "version": "1.0.0", "source_result_file": self.result_name.removeprefix("research/full-source-audit/"),
            "source_result_sha256": self.sha(self.result_name)}
        parallel = {"runner_sha256": self.sha("scripts/run_source_originality_full.py"),
            **{key: True for key in ["local_code_frozen_and_verified_after_merge", "package_coverage_exactly_once",
                "source_result_metadata_snapshot_verified_after_merge", "all_scanned_archive_hashes_verified_after_merge"]}}
        self.screens = {}
        for level in (40, 80):
            screen = {"audit": "research/full-source-audit/manifest.json", "audit_sha256": full["manifest_sha256"],
                "source_inventory": full["source_inventory"], "detector_sha256": self.sha("scripts/verify_source_originality.py"),
                "local_sources": [source], "parallel_method": parallel, "shard": {"coverage_verified_exactly_once": True},
                "method": {"minimum_tokens": level, "minimum_local_source_span_lines": 5 if level == 40 else 8,
                    "include_generated": True, "include_foreign_tests": True, "third_party_code_executed": False},
                "summary": {"packages": 1, "expected_packages": 1, "unresolved_packages": 0,
                    "limited_source_inventories": 0, "candidate_matches": 0},
                "packages": [package], "unresolved_packages": [], "source_inventory_limitations": [], "candidate_matches": []}
            if level == 80:
                screen["derivation"] = {"from": "full-source-clone-screen-40.json", "source_sha256": self.sha("research/originality-completion/full-source-clone-screen-40.json")}
            self.screens[level] = screen
            self.save(f"research/originality-completion/full-source-clone-screen-{level}.json", screen)
        semantic_manual = "research/originality-completion/manual-semantic-dispositions.json"
        self.save(semantic_manual, {"reviews": []})
        sources = [{"path": self.result_name, "sha256": self.sha(self.result_name)}]
        snapshot = {"inventory_sha256": full["manifest_sha256"], "modules_sha256": full["source_inventory"]["index_sha256"],
            "inputs_unchanged_after_join": True, "source_results": sources}
        self.semantic = {"complete_current_inventory": True, "summary": {"pending_manual_review": 0}, "pending": [],
            "snapshot": {**snapshot, "join_script_sha256": self.sha("scripts/review_source_semantic_hits.py"),
                "manual_reviews_sha256": self.sha(semantic_manual)}}
        self.save("research/originality-completion/full-source-semantic-review.json", self.semantic)
        manual_reports = []
        for filename in ["clock-neighbor-context-review.json", "association-neighbor-context-review.json"]:
            path = "research/originality-completion/" + filename
            self.save(path, {"reviews": []})
            manual_reports.append(self.record(path))
        self.neighbor = {"complete_current_inventory": True, "complete_saved_hit_context_reviews": True, "pending": [],
            "snapshot": {**snapshot, "join_script_sha256": self.sha("scripts/verify_neighbor_reviews.py"), "review_reports": manual_reports}}
        self.save("research/originality-completion/final-neighbor-review-coverage.json", self.neighbor)
        ledger = "research/originality-completion/supplemental-manual-dispositions.json"
        self.save(ledger, {"reviews": []})
        semantic_ledger = "research/originality-completion/manual-semantic-dispositions.json"
        # This is also the ledger used by the primary semantic join above.
        self.supplemental_review = {"complete": True, "pending": [], "reviews": [],
            "summary": {"pending_manual_review": 0, "all_keyword_hit_records": 0, "manually_reviewed_records": 0},
            "snapshot": {"supplemental_path": "research/full-source-audit/supplemental-binary-text.json",
                "supplemental_sha256": full["supplemental_sha256"], "main_manifest_sha256": full["manifest_sha256"],
                "source_nul_review_sha256": self.sha("research/full-source-audit/text-source-nul-review.json"),
                "join_script_sha256": self.sha("scripts/review_supplemental_semantic_hits.py"),
                "identity_script": {"path": "scripts/review_source_semantic_hits.py", "sha256": self.sha("scripts/review_source_semantic_hits.py")},
                "inputs_unchanged_after_join": True, "manual_ledgers": [self.record(semantic_ledger), self.record(ledger)]}}
        self.save("research/originality-completion/supplemental-source-semantic-review.json", self.supplemental_review)

    def test_current_rule_runtime_union_is_accepted(self):
        self.rules()
        self.assertEqual(package_local.verify_rule_evidence(self.root)["implemented_rule_count"], 1)

    def test_rule_failed_union_gap_or_stale_source_is_rejected(self):
        _, coverage = self.rules()
        coverage["successful"] = False
        self.save("research/normative-completion/test-coverage.json", coverage)
        with self.assertRaisesRegex(RuntimeError, "has not passed"):
            package_local.verify_rule_evidence(self.root)
        coverage["successful"] = True
        coverage["referenced_cli_inventory"]["cli_or_this_run_observed_rule_count"] = 0
        self.save("research/normative-completion/test-coverage.json", coverage)
        with self.assertRaisesRegex(RuntimeError, "Not all implemented"):
            package_local.verify_rule_evidence(self.root)
        self.write("wire/wire.mbt", "changed source\n")
        with self.assertRaisesRegex(RuntimeError, "stale"):
            package_local.verify_rule_evidence(self.root)

    def test_rule_current_cli_inventory_hash_is_required(self):
        inventory, _ = self.rules()
        inventory["new_observation"] = True
        self.save("research/normative-completion/rule-inventory.json", inventory)
        with self.assertRaisesRegex(RuntimeError, "current CLI inventory"):
            package_local.verify_rule_evidence(self.root)

    def test_complete_frozen_full_index_is_accepted(self):
        full = self.full()
        self.assertEqual(full["module_count"], 1)
        self.assertEqual(len(full["result_bindings"]), 1)

    def test_partial_or_unbound_full_source_audit_is_rejected(self):
        self.full()
        self.full_manifest["final"] = False
        self.save_full()
        with self.assertRaisesRegex(RuntimeError, "not final"):
            package_local.verify_full_source_evidence(self.root)
        self.full_manifest["final"] = True
        self.full_manifest["result_bindings"] = []
        self.save_full()
        with self.assertRaisesRegex(RuntimeError, "bindings.*exactly once"):
            package_local.verify_full_source_evidence(self.root)

    def test_stale_result_and_scanner_identity_are_rejected(self):
        self.full()
        self.result["scanner_version"] = 3
        self.save(self.result_name, self.result)
        with self.assertRaisesRegex(RuntimeError, "result hash is stale"):
            package_local.verify_full_source_evidence(self.root)
        self.full_manifest["result_bindings"][0]["sha256"] = self.sha(self.result_name)
        self.save_full()
        with self.assertRaisesRegex(RuntimeError, "different scanner"):
            package_local.verify_full_source_evidence(self.root)

    def test_stale_archive_verifier_cannot_reuse_success(self):
        self.full()
        self.write("research/full-source-audit/verify_manifest.py", "changed verifier\n")
        with self.assertRaisesRegex(RuntimeError, "verification.*stale"):
            package_local.verify_full_source_evidence(self.root)

    def test_supplement_hash_or_missing_longline_scan_cannot_reuse_success(self):
        self.full()
        self.supplement["long_line_candidate_files_expected"] = 1
        self.save("research/full-source-audit/supplemental-binary-text.json", self.supplement)
        with self.assertRaisesRegex(RuntimeError, "Supplemental.*incomplete or stale"):
            package_local.verify_full_source_evidence(self.root)
        self.supplement["long_line_candidate_files_expected"] = 0
        self.save("research/full-source-audit/supplemental-binary-text.json", self.supplement)
        self.write("research/full-source-audit/supplemental_binary_text_scan.py", "changed scanner\n")
        with self.assertRaisesRegex(RuntimeError, "Supplemental.*incomplete or stale"):
            package_local.verify_full_source_evidence(self.root)

    def test_bound_full_originality_evidence_is_accepted(self):
        full = self.full()
        self.originality(full)
        evidence = package_local.verify_originality_evidence(self.root, full)
        self.assertEqual(evidence["clone_reports"][40]["candidate_matches"], 0)

    def test_stale_local_source_cannot_reuse_clone_report(self):
        full = self.full()
        self.originality(full)
        self.write("wire/wire.mbt", "changed source\n")
        with self.assertRaisesRegex(RuntimeError, "stale for local"):
            package_local.verify_originality_evidence(self.root, full)

    def test_stale_clone_inventory_and_noninclusive_scan_are_rejected(self):
        full = self.full()
        self.originality(full)
        self.screens[40]["audit_sha256"] = "0" * 64
        self.save("research/originality-completion/full-source-clone-screen-40.json", self.screens[40])
        with self.assertRaisesRegex(RuntimeError, "current full inventory"):
            package_local.verify_originality_evidence(self.root, full)
        self.screens[40]["audit_sha256"] = full["manifest_sha256"]
        self.screens[40]["method"]["include_foreign_tests"] = False
        self.save("research/originality-completion/full-source-clone-screen-40.json", self.screens[40])
        with self.assertRaisesRegex(RuntimeError, "inclusive/frozen"):
            package_local.verify_originality_evidence(self.root, full)

    def test_semantic_empty_snapshot_or_changed_disposition_is_rejected(self):
        full = self.full()
        self.originality(full)
        self.semantic["snapshot"]["source_results"] = []
        self.save("research/originality-completion/full-source-semantic-review.json", self.semantic)
        with self.assertRaisesRegex(RuntimeError, "cover.*exactly once"):
            package_local.verify_originality_evidence(self.root, full)
        self.originality(full)
        self.save("research/originality-completion/manual-semantic-dispositions.json", {"reviews": ["new"]})
        with self.assertRaisesRegex(RuntimeError, "dispositions changed"):
            package_local.verify_originality_evidence(self.root, full)

    def test_pending_neighbor_context_cannot_claim_complete(self):
        full = self.full()
        self.originality(full)
        self.neighbor["pending"] = [{"path": "unreviewed.mbt"}]
        self.save("research/originality-completion/final-neighbor-review-coverage.json", self.neighbor)
        with self.assertRaisesRegex(RuntimeError, "unreviewed current hits"):
            package_local.verify_originality_evidence(self.root, full)

    def test_stale_or_pending_supplemental_semantic_review_is_rejected(self):
        full = self.full()
        self.originality(full)
        self.supplemental_review["snapshot"]["supplemental_sha256"] = "0" * 64
        self.save("research/originality-completion/supplemental-source-semantic-review.json", self.supplemental_review)
        with self.assertRaisesRegex(RuntimeError, "Supplemental semantic review.*stale"):
            package_local.verify_originality_evidence(self.root, full)
        self.originality(full)
        self.supplemental_review["pending"] = [{"line": 1}]
        self.save("research/originality-completion/supplemental-source-semantic-review.json", self.supplemental_review)
        with self.assertRaisesRegex(RuntimeError, "Supplemental semantic review.*pending"):
            package_local.verify_originality_evidence(self.root, full)


if __name__ == "__main__":
    unittest.main()
