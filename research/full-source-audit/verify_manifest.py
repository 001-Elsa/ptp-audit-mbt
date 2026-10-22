#!/usr/bin/env python3
"""Independently verify a frozen full-index inventory against its cached ZIPs.

This verifier uses only the standard library. It does not import the scanner,
execute third-party code, extract files, or retrieve a new index. By default it
rereads every ordinary ZIP member and validates the per-file SHA-256 inventory.
The external cache is required and intentionally is not part of the product ZIP.
"""
from __future__ import annotations

import argparse
import collections
import concurrent.futures
import datetime
import hashlib
import json
import pathlib
import sys
import zipfile

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]


def sha_file(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def ident(name, version):
    return hashlib.sha256((name + "\0" + version).encode()).hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def verify_archive(result, cache, members):
    pair = [result["name"], result["version"]]
    path = cache / (ident(*pair) + ".zip")
    require(path.is_file(), f"missing cache archive: {pair}")
    require(path.stat().st_size == result["archive_bytes"], f"archive byte count: {pair}")
    require(sha_file(path) == result["sha256"], f"archive SHA-256: {pair}")
    count = 0
    expanded = 0
    if members:
        with zipfile.ZipFile(path) as archive:
            actual = [item for item in archive.infolist() if not item.is_dir()]
            expected = result["files"]
            require(len(actual) == len(expected), f"member count: {pair}")
            for item, record in zip(actual, expected):
                require(item.filename == record["path"], f"member path/order: {pair}")
                require(not item.flag_bits & 1, f"encrypted member: {pair} {item.filename}")
                require(item.file_size == record["bytes"], f"member declared size: {pair} {item.filename}")
                digest = hashlib.sha256()
                length = 0
                with archive.open(item) as stream:
                    for block in iter(lambda: stream.read(1024 * 1024), b""):
                        digest.update(block)
                        length += len(block)
                require(length == record["bytes"], f"member actual size: {pair} {item.filename}")
                require(digest.hexdigest() == record["sha256"], f"member SHA-256: {pair} {item.filename}")
                count += 1
                expanded += length
        require(expanded == result["expanded_bytes"], f"expanded byte count: {pair}")
    return {"name": pair[0], "version": pair[1], "sha256": result["sha256"],
            "member_hashes_verified": count, "expanded_bytes_verified": expanded}


def verify(args):
    directory = args.directory.resolve()
    manifest_path = directory / "manifest.json"
    manifest_bytes = manifest_path.read_bytes()
    manifest = json.loads(manifest_bytes)
    modules_path = directory / "modules.json"
    modules = json.loads(modules_path.read_bytes())
    index = json.loads((directory / "index.json").read_bytes())
    raw_path = directory / index["raw_body_file"]
    pairs = [(m["name"], m["version"]) for m in modules]
    require(len(set(pairs)) == len(pairs), "duplicate index name/version pair")
    require(manifest["final"] is True, "manifest is not final")
    require(manifest["index"] == index, "manifest/index mismatch")
    require(json.loads(raw_path.read_bytes()) == modules, "raw/pretty index parse mismatch")
    require(sha_file(raw_path) == index["raw_sha256"], "raw index SHA-256")
    require(sha_file(modules_path) == index["modules_json_sha256"] == manifest["modules_json_sha256"], "pretty index SHA-256")
    for field in ("count", "unique_name_versions"):
        require(index[field] == len(pairs), f"index {field}")
    for field in ("expected_modules", "expected_unique_name_versions", "processed_modules"):
        require(manifest[field] == len(pairs), f"manifest {field}")
    require(manifest["statuses"] == {"ok": len(pairs), "limited": 0, "unavailable": 0, "error": 0}, "non-complete result status")
    require(manifest["unresolved"] == [], "unresolved results")
    scanner_path = ROOT / "scripts/audit_all_mooncakes_sources.py"
    require(sha_file(scanner_path) == manifest["scanner_sha256"], "scanner SHA-256")
    override_path = directory / "encoding-overrides.json"
    require(sha_file(override_path) == manifest["encoding_overrides_sha256"], "encoding configuration SHA-256")
    overrides = json.loads(override_path.read_bytes()).get("overrides", {})
    bindings = manifest["result_bindings"]
    require(len(bindings) == len(pairs), "binding count")
    require([(b["name"], b["version"]) for b in bindings] == pairs, "binding pair order/set")
    results = []
    counters = collections.Counter()
    strong_modules = set()
    strong_kinds = {"ptp_protocol", "ieee1588_context", "bmca", "correction_field", "port_identity"}
    expected_hit_modules = []
    for module, binding in zip(modules, bindings):
        pair = (binding["name"], binding["version"])
        relative = "results/" + ident(*pair) + ".json"
        require(binding["file"] == relative, f"binding path: {pair}")
        result_path = directory / relative
        require(sha_file(result_path) == binding["sha256"], f"result SHA-256: {pair}")
        result = json.loads(result_path.read_bytes())
        require((result["name"], result["version"]) == pair, f"result pair: {pair}")
        require(result["scanner_version"] == manifest["scanner_version"], f"result scanner version: {pair}")
        require(result["scanner_sha256"] == manifest["scanner_sha256"], f"result scanner SHA-256: {pair}")
        for field in ("yanked", "repository"):
            require(result.get(field) == module.get(field), f"result index metadata {field}: {pair}")
        require(result["status"] == "ok" and result["limitations"] == [], f"result limits/status: {pair}")
        require(all(not f["decode_replacement"] for f in result["files"]), f"decode replacement: {pair}")
        require(sum(f["kind"] == "text" for f in result["files"]) == result["text_files"], f"text count: {pair}")
        require(sum(f["kind"] == "binary" for f in result["files"]) == result["binary_files"], f"binary count: {pair}")
        require(sum(f["bytes"] for f in result["files"] if f["kind"] == "text") == result["text_bytes"], f"text bytes: {pair}")
        indexed_files = {f["path"]: f for f in result["files"]}
        for path, override in overrides.get(ident(*pair) + ".zip", {}).items():
            require(path in indexed_files, f"configured member missing: {pair} {path}")
            record = indexed_files[path]
            for field in ("basis", "classification"):
                recorded_field = "encoding_basis" if field == "basis" else field
                require(record.get(recorded_field) == override.get(field), f"override {field}: {pair} {path}")
            if "encoding" in override and record["kind"] == "text":
                require(record["encoding"] == override["encoding"], f"override encoding: {pair} {path}")
            if override.get("classification") == "binary-fixture":
                require(record["kind"] == "binary", f"override binary classification: {pair} {path}")
        for field in ("text_files", "binary_files", "text_bytes", "archive_bytes", "expanded_bytes"):
            counters[field] += result[field]
        if any(strong_kinds.intersection(h["kinds"]) for h in result["hits"]):
            strong_modules.add(pair)
        if result["hits"]:
            expected_hit_modules.append({"name": pair[0], "version": pair[1], "result": relative,
                                         "kinds": sorted({k for h in result["hits"] for k in h["kinds"]}),
                                         "hit_count": len(result["hits"])})
        results.append(result)
    order_key = lambda item: (item["name"], item["version"])
    require(sorted(expected_hit_modules, key=order_key) == sorted(manifest["hit_modules"], key=order_key), "derived hit-module inventory")
    for field in ("text_files", "text_bytes", "archive_bytes"):
        require(counters[field] == manifest[field], f"manifest aggregate: {field}")
    cache = args.cache.resolve() if args.cache else pathlib.Path(manifest["cache"])
    verified = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        jobs = [pool.submit(verify_archive, result, cache, not args.archives_only) for result in results]
        for i, future in enumerate(concurrent.futures.as_completed(jobs), 1):
            verified.append(future.result())
            if i % 250 == 0 or i == len(jobs):
                print(json.dumps({"verified_archives": i, "expected": len(jobs)}), flush=True)
    # Do not certify a manifest that changed while the cache was being checked.
    require(manifest_path.read_bytes() == manifest_bytes, "manifest changed during verification")
    verified.sort(key=lambda x: (x["name"], x["version"]))
    return {"schema": "mooncakes-full-source-verification/v1", "result": "pass",
            "checked_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "verifier_sha256": sha_file(pathlib.Path(__file__)),
            "manifest_sha256": hashlib.sha256(manifest_bytes).hexdigest(),
            "scanner_sha256": manifest["scanner_sha256"], "scanner_version": manifest["scanner_version"],
            "index_raw_sha256": index["raw_sha256"], "index_pretty_sha256": index["modules_json_sha256"],
            "encoding_overrides_sha256": manifest["encoding_overrides_sha256"],
            "expected_modules": len(pairs), "verified_results": len(results), "verified_archives": len(verified),
            "verification_depth": "archive_and_all_member_sha256" if not args.archives_only else "archive_sha256",
            "member_hashes_verified": sum(v["member_hashes_verified"] for v in verified),
            "expanded_bytes_verified": sum(v["expanded_bytes_verified"] for v in verified),
            "counts": dict(counters), "strong_hit_modules": len(strong_modules),
            "checks": ["unique current index pairs", "exact raw/pretty parse equality and SHA-256",
                       "final manifest with all statuses ok and no unresolved result", "scanner/configuration SHA-256",
                       "every current result binding, scanner identity and index metadata", "per-file encoding overrides and derived hit-module inventory", "file and byte aggregate consistency",
                       "every cached ZIP SHA-256", "every ordinary ZIP member path, size, CRC read and SHA-256" if not args.archives_only else "per-member verification not requested",
                       "frozen manifest throughout verification"],
            "archives": verified,
            "boundary": "Verifies inventory integrity and coverage of the captured current versions, not semantic originality or unlisted/historical packages."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=pathlib.Path, default=HERE)
    parser.add_argument("--cache", type=pathlib.Path)
    parser.add_argument("--workers", type=int, default=8)
    parser.add_argument("--archives-only", action="store_true")
    args = parser.parse_args()
    try:
        output = verify(args)
    except (ValueError, KeyError, OSError, zipfile.BadZipFile) as error:
        print(json.dumps({"result": "fail", "error": str(error)}), file=sys.stderr)
        return 1
    target = args.directory / "verification.json"
    target.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({k: v for k, v in output.items() if k != "archives"}, ensure_ascii=False), flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
