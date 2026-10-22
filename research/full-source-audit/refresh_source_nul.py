#!/usr/bin/env python3
"""Refresh selected-source NUL coverage, reusing only byte-identical reviewed members.

All archives and selected members are read and hashed again. A newly observed
NUL-bearing member without existing byte-bound manual evidence stops the refresh;
this script never invents a manual encoding classification.
"""
from __future__ import annotations

import argparse
import collections
import concurrent.futures
import datetime
import hashlib
import importlib.util
import json
import pathlib
import zipfile

HERE = pathlib.Path(__file__).resolve().parent


def sha(path):
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--previous", type=pathlib.Path, required=True)
    parser.add_argument("--workers", type=int, default=6)
    args = parser.parse_args()
    args.previous = args.previous.resolve()
    prior = json.loads(args.previous.read_bytes())
    manifest_bytes = (HERE / "manifest.json").read_bytes()
    manifest = json.loads(manifest_bytes)
    modules_bytes = (HERE / "modules.json").read_bytes()
    modules = json.loads(modules_bytes)
    suffixes = set(prior["suffixes"])
    reviewed = {(row["path"], row["sha256"]): row
                for archive in prior["archives"] for row in archive["nul_members"]}
    spec = importlib.util.spec_from_file_location("nul_verifier", HERE / "audit_source_nul.py")
    verifier = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(verifier)
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    bound_results = {}
    for binding in manifest["result_bindings"]:
        path = HERE / binding["file"]
        raw = path.read_bytes()
        assert hashlib.sha256(raw).hexdigest() == binding["sha256"]
        bound_results[(binding["name"], binding["version"])] = (binding, json.loads(raw))

    def scan(module):
        pair = module["name"], module["version"]
        binding, result = bound_results[pair]
        cache = pathlib.Path(result["cache_file"])
        assert sha(cache) == result["sha256"] and cache.stat().st_size == result["archive_bytes"]
        inventory = hashlib.sha256()
        count = total = 0
        nuls = []
        with zipfile.ZipFile(cache) as archive:
            members = [info for info in archive.infolist() if not info.is_dir()]
            assert len(members) == len(result["files"])
            for info, expected in zip(members, result["files"]):
                assert info.filename == expected["path"]
                path = pathlib.PurePosixPath(info.filename)
                if expected["kind"] != "text" or not (path.suffix.lower() in suffixes or path.name.lower().startswith("readme")):
                    continue
                h = hashlib.sha256()
                length = nul_count = 0
                with archive.open(info) as stream:
                    for block in iter(lambda: stream.read(1024 * 1024), b""):
                        h.update(block)
                        length += len(block)
                        nul_count += block.count(0)
                actual = h.hexdigest()
                assert length == info.file_size == expected["bytes"] and actual == expected["sha256"]
                inventory.update(json.dumps([info.filename, length, actual], ensure_ascii=False, separators=(",", ":")).encode() + b"\n")
                count += 1
                total += length
                if nul_count:
                    record = reviewed.get((info.filename, actual))
                    if record is None:
                        raise ValueError(f"New NUL member needs manual review: {pair} {info.filename} sha={actual}")
                    content = archive.read(info)
                    verifier.verify_manual_bytes(content, record)
                    assert record["inventory_encoding"] == expected["encoding"] and record["nul_bytes"] == nul_count
                    nuls.append(record)
        assert sha(cache) == result["sha256"]
        return {"name": pair[0], "version": pair[1], "result_file": binding["file"],
                "result_sha256": binding["sha256"], "archive_cache_file": str(cache),
                "archive_sha256": result["sha256"], "archive_bytes": result["archive_bytes"],
                "selected_members": count, "selected_bytes": total, "nul_members": nuls,
                "checked_member_inventory_sha256": inventory.hexdigest()}

    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        archives = list(pool.map(scan, modules))
    assert (HERE / "manifest.json").read_bytes() == manifest_bytes
    assert (HERE / "modules.json").read_bytes() == modules_bytes
    for binding, _ in bound_results.values():
        assert sha(HERE / binding["file"]) == binding["sha256"]
    categories = collections.Counter(row["manual_review"]["category"]
                                     for archive in archives for row in archive["nul_members"])
    count = len(modules)
    now = datetime.datetime.now(datetime.timezone.utc).isoformat()
    report = {**prior, "started_at": started, "completed_at": now,
              "scope": f"All {count} current-index v4/ok results bound by the frozen final main manifest. Every selected source/README member read again; prior manual NUL evidence reused only for identical path and member SHA-256.",
              "modules_json_sha256": hashlib.sha256(modules_bytes).hexdigest(),
              "main_manifest_sha256": hashlib.sha256(manifest_bytes).hexdigest(),
              "main_scanner_version": manifest["scanner_version"], "main_scanner_sha256": manifest["scanner_sha256"],
              "encoding_overrides_sha256": manifest["encoding_overrides_sha256"],
              "index_modules": count, "snapshot_v4_ok_results": count, "completed_results": count,
              "results_with_selected_members": sum(bool(row["selected_members"]) for row in archives),
              "selected_members": sum(row["selected_members"] for row in archives),
              "selected_bytes": sum(row["selected_bytes"] for row in archives),
              "nul_members": sum(len(row["nul_members"]) for row in archives), "archives": archives,
              "previous_snapshot": {"path": str(args.previous.relative_to(HERE)), "sha256": sha(args.previous),
                                    "completed_results": prior["completed_results"], "completed_at": prior["completed_at"]},
              "manual_review": {"reviewed_at": now, "nul_member_categories": dict(categories), "pending_members": 0,
                                "conclusion": "All current NUL members retain byte-identical previously reviewed encoding/literal evidence; every recorded byte context is independently checked. No new manual classification was generated."},
              "frozen_for_supplemental_binding_at": now,
              "refresh_script_sha256": sha(pathlib.Path(__file__)),
              "checks": [f"final main manifest and all {count} result bindings verified", *prior["checks"][1:]]}
    target = HERE / "text-source-nul-review.json"
    target.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({k: report[k] for k in ("result", "completed_results", "selected_members", "selected_bytes", "nul_members")}))


if __name__ == "__main__":
    main()
