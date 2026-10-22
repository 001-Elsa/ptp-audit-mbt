#!/usr/bin/env python3
"""Bind manually read clock/association contexts to the final source snapshot.

The original incremental reviews are preserved. A metadata refresh can reuse a
review only when package version, ZIP hash, file, line and exact hit text agree.
This is a coverage join, never automatic semantic judgment or a uniqueness claim.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "research/full-source-audit"
DEST = ROOT / "research/originality-completion"


def digest(data):
    return hashlib.sha256(data).hexdigest()


def hit_identity(package, hit):
    data = {"name": package["name"], "version": package["version"], "zip_sha256": package.get("zip_sha256", package.get("sha256")), "path": hit["path"], "line": hit["line"], "text": hit.get("text", hit.get("match_excerpt"))}
    return digest(json.dumps(data, ensure_ascii=False, sort_keys=True).encode())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--require-complete", action="store_true")
    args = parser.parse_args()
    watched = {}

    def read(path):
        data = path.read_bytes()
        watched[path] = digest(data)
        return json.loads(data)

    inventory = read(BASE / "manifest.json")
    modules = read(BASE / "modules.json")
    if watched[BASE / "modules.json"] != inventory["index"]["modules_json_sha256"]:
        raise ValueError("Current source index hash differs from manifest")
    keys = [(m["name"], m["version"]) for m in modules]
    expected = set(keys)
    if len(keys) != len(expected):
        raise ValueError("Duplicate module name/version pairs")
    specifications = [
        ("clock_sync", "clock-neighbor-context-review.json", "reviews"),
        ("request_response_deadline", "association-neighbor-context-review.json", "packages"),
    ]
    reviewed, review_reports = {}, []
    for kind, filename, collection in specifications:
        path = DEST / filename
        report = read(path)
        mapping = {}
        for package in report[collection]:
            for hit in package["hits"]:
                ident = hit_identity(package, hit)
                if ident in mapping:
                    raise ValueError(f"Duplicate reviewed hit in {filename}")
                mapping[ident] = {"review_report": str(path.relative_to(ROOT)), "name": package["name"], "version": package["version"], "path": hit["path"], "line": hit["line"], "original_result_sha256": package["result_sha256"]}
        reviewed[kind] = mapping
        review_reports.append({"path": str(path.relative_to(ROOT)), "sha256": watched[path], "kind": kind, "reviewed_package_count": len(report[collection]), "reviewed_hit_count": len(mapping)})

    seen, source_results, joined, pending = set(), [], [], []
    scanner_versions, source_statuses = Counter(), Counter()
    for path in sorted((BASE / "results").glob("*.json")):
        package = read(path)
        key = package["name"], package["version"]
        if key not in expected:
            # An archived result is not part of the current index snapshot.
            watched.pop(path)
            continue
        if key in seen:
            raise ValueError(f"Duplicate current source result: {key}")
        seen.add(key)
        scanner_versions[str(package.get("scanner_version"))] += 1
        source_statuses[str(package.get("status"))] += 1
        source_results.append({"path": str(path.relative_to(ROOT)), "sha256": watched[path], "name": key[0], "version": key[1], "scanner_version": package.get("scanner_version")})
        for hit in package.get("hits", []):
            for kind in set(hit["kinds"]) & reviewed.keys():
                ident = hit_identity(package, hit)
                current = {"source_hit_id": ident, "kind": kind, "name": key[0], "version": key[1], "zip_sha256": package.get("sha256"), "path": hit["path"], "line": hit["line"], "text": hit["text"], "current_result_sha256": watched[path]}
                if ident in reviewed[kind]:
                    current["manual_context_reference"] = reviewed[kind][ident]
                    joined.append(current)
                else:
                    pending.append(current)
    current_inventory_complete = inventory.get("final") is True and seen == expected and scanner_versions == {str(inventory.get("scanner_version")): len(expected)} and source_statuses == {"ok": len(expected)}
    complete = current_inventory_complete and not pending
    for path, expected_hash in watched.items():
        if digest(path.read_bytes()) != expected_hash:
            raise ValueError(f"Review/source snapshot changed while joining: {path}")
    summary = {}
    for kind, _, _ in specifications:
        rows = [r for r in joined + pending if r["kind"] == kind]
        summary[kind] = {"packages": len({(r["name"], r["version"]) for r in rows}), "hits": len(rows), "manually_reviewed_hits": sum(r["kind"] == kind for r in joined), "pending_manual_review": sum(r["kind"] == kind for r in pending)}
    result = {"schema": "ptp-neighbor-context-review-coverage/v1", "complete_current_inventory": current_inventory_complete, "complete_saved_hit_context_reviews": complete, "summary": summary, "snapshot": {"inventory_sha256": watched[BASE / "manifest.json"], "modules_sha256": watched[BASE / "modules.json"], "join_script_sha256": digest(Path(__file__).read_bytes()), "inputs_unchanged_after_join": True, "review_reports": review_reports, "source_results": source_results}, "joined": joined, "pending": pending, "method": "A saved manual review is reused only for an identical name/version/ZIP SHA/file/line/exact text occurrence; changes to scanner metadata alone do not turn an already-read occurrence into an unread one.", "limitations": ["This validates the enumerated lexical-hit contexts and explicitly expanded source regions, not an unaided full semantic reading of every file in every package.", "Actual clock measurement, correlation, windows, deadlines and report intersections remain real. This report is not an absolute non-similarity or eligibility certificate."]}
    destination = DEST / "final-neighbor-review-coverage.json"
    destination.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({"complete_saved_hit_context_reviews": complete, "summary": summary}, ensure_ascii=False))
    if args.require_complete and not complete:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
