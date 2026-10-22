#!/usr/bin/env python3
"""Parallel, read-only inclusive source screening; merge with coverage checks.

The stricter 80-token/8-line report is explicitly derived from the complete
40-token/5-line candidate superset. No third-party code is executed.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import copy
import contextlib
import io
import json
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

import verify_source_originality as detector
from verify_source_originality import ROOT, digest, file_digest, local_sources, source_rows


RUNNER_FILE = Path(__file__).resolve()
LOADED_RUNNER_SHA256 = file_digest(RUNNER_FILE)


def strict_candidate(match):
    if match["tokens"] < 80 or match["local_lines"][1] - match["local_lines"][0] + 1 < 8:
        return False
    if match["kind"] == "consistent_identifier_rename_block":
        return match["external_lines"][1] - match["external_lines"][0] + 1 >= 8
    return match["kind"] == "exact_tokens"


def merge(shards, audit, destination):
    if file_digest(RUNNER_FILE) != LOADED_RUNNER_SHA256:
        raise ValueError("Runner source changed after loading; rerun the frozen snapshot")
    first = shards[0]
    for shard in shards:
        for key in ("audit_sha256", "detector_sha256", "local_sources", "method", "source_inventory"):
            if shard[key] != first[key]:
                raise ValueError(f"Shard source snapshot differs: {key}")
    current_audit_bytes = audit.read_bytes()
    expected_rows, current_inventory = source_rows(audit, current_audit_bytes)
    if current_inventory != first["source_inventory"]:
        raise ValueError("Source index or per-package result metadata changed while screening; freeze and rerun")
    if current_inventory is not None and current_inventory["final"] is not True:
        raise ValueError("Full source inventory is not final; wait for its frozen manifest")
    expected = {(row["name"], row["version"]) for row in expected_rows}
    packages = [row for shard in shards for row in shard["packages"]]
    unresolved = [row for shard in shards for row in shard["unresolved_packages"]]
    got = [(row["name"], row["version"]) for row in packages + unresolved]
    if len(got) != len(set(got)) or set(got) != expected:
        raise ValueError("Shard coverage is duplicated or does not equal the captured full index")
    if digest(current_audit_bytes) != first["audit_sha256"]:
        raise ValueError("Source audit changed while screening; freeze and rerun")
    if file_digest(detector.DETECTOR_FILE) != first["detector_sha256"]:
        raise ValueError("Detector source changed while screening; freeze and rerun")
    current_local = {path: sha for path, _, sha in local_sources()}
    if current_local != {row["path"]: row["sha256"] for row in first["local_sources"]}:
        raise ValueError("Local product code changed while screening; rerun against final source")
    for package in packages:
        if file_digest(ROOT / package["evidence_file"]) != package["zip_sha256"]:
            raise ValueError(f"Source ZIP changed while screening: {package['name']}@{package['version']}")
    result = copy.deepcopy(first)
    result["shard"] = {"count": len(shards), "merged": True, "expected_all_packages": len(expected), "coverage_verified_exactly_once": True}
    result["packages"] = sorted(packages, key=lambda r: (r["name"], r["version"]))
    for key in ("candidate_matches", "explicit_exclusions", "unresolved_packages", "source_inventory_limitations"):
        result[key] = [row for shard in shards for row in shard[key]]
    summary = result["summary"]
    for key in ("packages", "unresolved_packages", "limited_source_inventories", "expected_packages", "external_production_files", "external_scanned_files", "external_tokens", "candidate_matches", "identified_generated_files", "excluded_generated_files", "identified_test_files", "excluded_test_files"):
        summary[key] = sum(shard["summary"][key] for shard in shards)
    result["parallel_method"] = {"workers": len(shards), "partition": "Captured index row ordinal modulo worker count", "local_code_frozen_and_verified_after_merge": True, "package_coverage_exactly_once": True, "source_result_metadata_snapshot_verified_after_merge": True, "all_scanned_archive_hashes_verified_after_merge": True, "runner_sha256": LOADED_RUNNER_SHA256}
    (destination / "full-source-clone-screen-40.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")

    strict = copy.deepcopy(result)
    strict["candidate_matches"] = [row for row in result["candidate_matches"] if strict_candidate(row)]
    strict["method"]["minimum_tokens"] = 80
    strict["method"]["minimum_local_source_span_lines"] = 8
    strict["method"]["minimum_foreign_source_span_lines_for_renamed_blocks"] = 8
    strict["summary"]["candidate_matches"] = len(strict["candidate_matches"])
    strict["derivation"] = {"from": "full-source-clone-screen-40.json", "source_sha256": file_digest(destination / "full-source-clone-screen-40.json"), "performed_another_scan": False, "superset_proof": "Both thresholds use the same 32-token seeds. Maximal exact-span extension and deduplication occur before threshold filtering, so every >=80-token/>=8-local-line exact match is present in the >=40-token/>=5-local-line result. Whole-block identifier canonicalization is identical and requires >=80 tokens and >=8 lines on both local and foreign blocks, hence is also a subset. No normalization variant is omitted."}
    per_package = {}
    for row in strict["candidate_matches"]:
        key = (row["package"], row["version"])
        per_package[key] = per_package.get(key, 0) + 1
    for package in strict["packages"]:
        package["candidate_matches"] = per_package.get((package["name"], package["version"]), 0)
    (destination / "full-source-clone-screen-80.json").write_text(json.dumps(strict, ensure_ascii=False, indent=2) + "\n")
    return result, strict


def self_test():
    """Only controlled local text/ZIPs; verify derivation and snapshot rejection."""
    saved_root = detector.ROOT
    with tempfile.TemporaryDirectory(prefix="ptp-clone-runner-") as folder:
        try:
            root = Path(folder)
            detector.ROOT = root
            sample = "///|\nfn original(value : Int) -> Int {\n" + "\n".join(f" let part{i} = value + {i};" for i in range(30)) + "\n part29\n}\n"
            (root / "local.mbt").write_text(sample)
            inventory = root / "inventory"
            (inventory / "results").mkdir(parents=True)
            index = inventory / "modules.json"
            index.write_text(json.dumps([{"name": "controlled/runner-fixture", "version": "0"}]))
            audit = inventory / "manifest.json"
            audit.write_text(json.dumps({"schema": "mooncakes-full-source-scan/v1", "final": True, "index": {"modules_json_sha256": file_digest(index)}}))
            archive = root / "source.zip"
            with zipfile.ZipFile(archive, "w") as z:
                z.writestr("exact.mbt", sample)
                renamed = sample.replace("original", "renamed").replace("value", "input").replace("part", "item")
                z.writestr("renamed.mbt", renamed)
                # Same token stream but only five code-span lines: normalized
                # 40/5 accepts it and normalized 80/8 must exclude it.
                compact_lines = renamed.splitlines()
                compact = "\n".join([compact_lines[0], compact_lines[1], " ".join(compact_lines[2:17]), " ".join(compact_lines[17:32]), compact_lines[32], compact_lines[33]]) + "\n"
                z.writestr("renamed_compact.mbt", compact)
            metadata = inventory / "results/one.json"
            row = {"name": "controlled/runner-fixture", "version": "0", "status": "ok", "cache_file": str(archive), "sha256": file_digest(archive)}
            metadata.write_text(json.dumps(row))
            destination = root / "out"
            destination.mkdir()
            with contextlib.redirect_stdout(io.StringIO()):
                low = detector.screen(audit, root / "low.json", 40, 5, True, include_tests=True)
                direct = detector.screen(audit, root / "direct.json", 80, 8, True, include_tests=True)
            _, derived = merge([low], audit, destination)
            assert derived["candidate_matches"] == direct["candidate_matches"]
            assert {m["kind"] for m in derived["candidate_matches"]} == {"exact_tokens", "consistent_identifier_rename_block"}
            assert any(m["external_path"] == "renamed_compact.mbt" and m["kind"] == "consistent_identifier_rename_block" for m in low["candidate_matches"])
            assert not any(m["external_path"] == "renamed_compact.mbt" and m["kind"] == "consistent_identifier_rename_block" for m in derived["candidate_matches"])

            def rejected(reason):
                try:
                    merge([low], audit, destination)
                except ValueError as error:
                    assert reason in str(error), str(error)
                else:
                    raise AssertionError("Changed source snapshot was accepted")

            saved_metadata = metadata.read_bytes()
            row["sha256"] = "0" * 64
            metadata.write_text(json.dumps(row))
            rejected("per-package result metadata changed")
            metadata.write_bytes(saved_metadata)
            saved_index = index.read_bytes()
            index.write_bytes(saved_index + b"\n")
            rejected("hash recorded in the audit manifest")
            index.write_bytes(saved_index)
            saved_archive = archive.read_bytes()
            archive.write_bytes(saved_archive + b"changed")
            rejected("Source ZIP changed")
            archive.write_bytes(saved_archive)
            (root / "local.mbt").write_text(sample + "// changed source hash\n")
            rejected("Local product code changed")
        finally:
            detector.ROOT = saved_root
    assert not strict_candidate({"tokens": 79, "local_lines": [1, 8], "external_lines": [1, 8], "kind": "exact_tokens"})
    assert not strict_candidate({"tokens": 80, "local_lines": [1, 7], "external_lines": [1, 8], "kind": "exact_tokens"})
    assert strict_candidate({"tokens": 80, "local_lines": [1, 8], "external_lines": [1, 1], "kind": "exact_tokens"})
    assert not strict_candidate({"tokens": 80, "local_lines": [1, 8], "external_lines": [1, 7], "kind": "consistent_identifier_rename_block"})
    assert strict_candidate({"tokens": 80, "local_lines": [1, 8], "external_lines": [1, 8], "kind": "consistent_identifier_rename_block"})
    print("source-clone runner self-test: passed")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--audit", type=Path, default=ROOT / "research/full-source-audit/manifest.json")
    parser.add_argument("--output-dir", type=Path, default=ROOT / "research/originality-completion")
    parser.add_argument("--workers", type=int, default=6)
    parser.add_argument("--max-source-bytes", type=int, default=32 * 1024 * 1024)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return
    if not 1 <= args.workers <= 12:
        parser.error("workers must be 1 through 12")
    args.audit = args.audit.resolve()
    args.output_dir = args.output_dir.resolve()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    shard_dir = args.output_dir / "clone-shards"
    shard_dir.mkdir(exist_ok=True)
    snapshot = file_digest(args.audit)
    _, initial_inventory = source_rows(args.audit, args.audit.read_bytes())
    if initial_inventory is not None and initial_inventory["final"] is not True:
        parser.error("Full source inventory is not final; wait for its frozen manifest")

    def run(index):
        output = shard_dir / f"part-{index:02}.json"
        log = shard_dir / f"part-{index:02}.log"
        command = [sys.executable, str(ROOT / "scripts/verify_source_originality.py"), "--audit", str(args.audit), "--output", str(output), "--minimum-tokens", "40", "--minimum-lines", "5", "--include-generated", "--include-tests", "--max-source-bytes", str(args.max_source_bytes), "--progress-every", "50", "--shard-count", str(args.workers), "--shard-index", str(index)]
        with log.open("w") as stream:
            completed = subprocess.run(command, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT)
        if completed.returncode:
            raise RuntimeError(f"Source-clone worker {index} failed; inspect {log}")
        data = json.loads(output.read_text())
        if data["audit_sha256"] != snapshot:
            raise ValueError("Source inventory changed between workers")
        print(json.dumps({"completed_worker": index, "summary": data["summary"]}), flush=True)
        return index, data

    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as executor:
        values = dict(executor.map(run, range(args.workers)))
    low, high = merge([values[i] for i in range(args.workers)], args.audit, args.output_dir)
    print(json.dumps({"inclusive_40_5": low["summary"], "derived_80_8": high["summary"], "explicit_exclusions": len(low["explicit_exclusions"])}), flush=True)


if __name__ == "__main__":
    main()
