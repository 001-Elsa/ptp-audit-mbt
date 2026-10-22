#!/usr/bin/env python3
"""Join every supplemental keyword occurrence to a saved manual disposition.

The scanner reads bytes; the manual ledgers document human context review. This
script only joins those records and refuses incomplete or changed snapshots.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter
from pathlib import Path

from review_source_semantic_hits import identity

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "research/full-source-audit"
DEST = ROOT / "research/originality-completion"


def digest(data):
    return hashlib.sha256(data).hexdigest()


def supplemental_hits(scan):
    for archive in scan["archives"]:
        package = {"name": archive["name"], "version": archive["version"], "sha256": archive["archive_sha256"]}
        for member in archive["binary_members"]:
            for hit in member["hits"]:
                yield package, {"path": member["path"], **hit}, "original_binary_" + member["classification"], member["sha256"]
            for hit in member.get("mixed_log_byte_view", {}).get("hits", []):
                yield package, {"path": member["path"], **hit}, "identified_mixed_log_reversible_byte_view", member["sha256"]
        for member in archive["long_line_text_members"]:
            for hit in member["corrected_long_line_hits"]:
                yield package, {"path": member["path"], **hit}, "complete_logical_line", member["sha256"]
        for member in archive.get("source_nul_text_members", []):
            # These are readable source members with literal NUL bytes. The
            # scanner records both the strict UTF-8 view and the reversible
            # NUL-stripped byte probe; neither is silently omitted here.
            for hit in member.get("strict_utf8_hits", []):
                yield package, {"path": member["path"], **hit}, "source_nul_strict_utf8_view", member["sha256"]
            for hit in member.get("nul_stripped_ascii_byte_probe", {}).get("hits", []):
                yield package, {"path": member["path"], **hit}, "source_nul_nul_stripped_ascii_probe", member["sha256"]
            # A few source-NUL records carry an individually identified short
            # mixed README tail. It is a byte-view probe, not an encoding claim.
            tail = member.get("identified_mixed_readme_tail")
            if tail:
                for hit in tail.get("hits", []):
                    yield package, {"path": member["path"], **hit}, "identified_mixed_readme_tail", member["sha256"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--require-complete", action="store_true")
    args = parser.parse_args()
    watched = {}

    def read(path):
        raw = path.read_bytes()
        watched[path] = digest(raw)
        return json.loads(raw)

    manifest = read(BASE / "manifest.json")
    source_path = BASE / "supplemental-binary-text.json"
    scan = read(source_path)
    if manifest.get("final") is not True or scan.get("result") != "pass":
        raise ValueError("Main and supplemental inventories are not both final/pass")
    if scan["main_manifest_sha256"] != watched[BASE / "manifest.json"]:
        raise ValueError("Supplement does not bind current main manifest")
    modules = read(BASE / "modules.json")
    if scan["index_pretty_sha256"] != watched[BASE / "modules.json"] or scan["expected_modules"] != len(modules) or scan["verified_result_bindings"] != len(modules):
        raise ValueError("Supplement does not bind complete current module index")
    if scan["binary_members_expected"] != scan["binary_members_read_and_hashed"] or scan["long_line_candidate_files_expected"] != scan["long_line_candidate_files_checked"]:
        raise ValueError("Supplement left members unchecked")
    if scan.get("source_nul_files_expected") != scan.get("source_nul_files_checked"):
        raise ValueError("Supplement left NUL-containing source members unchecked")
    nul_review_path = BASE / "text-source-nul-review.json"
    nul_review_bytes = nul_review_path.read_bytes()
    watched[nul_review_path] = digest(nul_review_bytes)
    if scan.get("source_nul_review_sha256") != watched[nul_review_path]:
        raise ValueError("Supplement does not bind frozen source-NUL review")
    if scan["result_bindings"] != manifest["result_bindings"]:
        raise ValueError("Supplement result bindings differ from main inventory")
    for binding in scan["result_bindings"]:
        rel = Path(binding["file"])
        if rel.is_absolute() or ".." in rel.parts or rel.parts[0] != "results":
            raise ValueError("Unsafe source result binding")
        read(BASE / rel)
        if watched[BASE / rel] != binding["sha256"]:
            raise ValueError("Supplement source result has changed: " + binding["file"])
    scanner_path = BASE / "supplemental_binary_text_scan.py"
    scanner_bytes = scanner_path.read_bytes()
    watched[scanner_path] = digest(scanner_bytes)
    if scan["supplemental_scanner_sha256"] != watched[scanner_path]:
        raise ValueError("Supplemental scanner source changed after scan")

    decisions, ledger_bindings = {}, []
    for filename in ("manual-semantic-dispositions.json", "supplemental-manual-dispositions.json"):
        path = DEST / filename
        ledger = read(path)
        ledger_bindings.append({"path": str(path.relative_to(ROOT)), "sha256": watched[path]})
        for row in ledger["reviews"]:
            ident = row["source_hit_id"]
            if ident in decisions and decisions[ident] != row:
                raise ValueError("Conflicting manual disposition for " + ident)
            decisions[ident] = row
    reviews, pending, kinds = [], [], Counter()
    for package, hit, origin, member_hash in supplemental_hits(scan):
        ident = identity(package, hit)
        row = {"source_hit_id": ident, "name": package["name"], "version": package["version"], "zip_sha256": package["sha256"], "member_sha256": member_hash, "origin": origin, **hit}
        kinds.update(hit["kinds"])
        if ident in decisions:
            row["manual_review"] = decisions[ident]
            reviews.append(row)
        else:
            pending.append(row)
    for path, expected in watched.items():
        if digest(path.read_bytes()) != expected:
            raise ValueError("Supplement/review input changed while joining: " + str(path))
    result = {"schema": "ptp-supplemental-source-hit-review/v1", "complete": not pending, "summary": {"all_keyword_hit_records": len(reviews) + len(pending), "manually_reviewed_records": len(reviews), "pending_manual_review": len(pending), "keyword_kinds": dict(kinds), "source_nul_members_expected": scan.get("source_nul_files_expected"), "source_nul_members_checked": scan.get("source_nul_files_checked"), "identified_mixed_readme_tails": scan.get("identified_mixed_readme_tails")}, "snapshot": {"supplemental_path": str(source_path.relative_to(ROOT)), "supplemental_sha256": watched[source_path], "main_manifest_sha256": watched[BASE / "manifest.json"], "source_nul_review_sha256": scan.get("source_nul_review_sha256"), "manual_ledgers": ledger_bindings, "join_script_sha256": digest(Path(__file__).read_bytes()), "identity_script": {"path": "scripts/review_source_semantic_hits.py", "sha256": digest((ROOT / "scripts/review_source_semantic_hits.py").read_bytes())}, "inputs_unchanged_after_join": True}, "reviews": reviews, "pending": pending, "scope": "Every saved supplemental keyword occurrence, including ordinary follow-up words and general clock/association/audit categories; source-NUL strict/byte probes and identified mixed README tails are enumerated explicitly; only saved human dispositions count as reviewed.", "limitations": ["This does not transform byte-view text into a claim about original encoding.", "A complete occurrence review is not a proof of all semantic non-equivalence or absolute zero similarity.", "Actual standard layouts and generic product-capability intersections remain documented."]}
    (DEST / "supplemental-source-semantic-review.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({"complete": not pending, "summary": result["summary"]}, ensure_ascii=False))
    if args.require_complete and pending:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
