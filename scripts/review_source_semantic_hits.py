#!/usr/bin/env python3
"""Join saved source hits to explicit, manually reviewed per-hit dispositions.

Unreviewed hits remain visible. This script cannot create human review or prove
semantic non-equivalence; it only checks coverage of the saved manual records.
"""
from pathlib import Path
from collections import Counter
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "research/full-source-audit"
DEST = ROOT / "research/originality-completion"
STRONG = {"ptp_protocol", "ieee1588_context", "bmca", "correction_field", "port_identity"}
SPECIFIC_MESSAGE_ANCHOR = re.compile(r"(?i)\bdelay[ _-]*(?:req|resp)\b|\bpdelay[ _-]*(?:req|resp)\b|\b(?:two[ _-]*step[ _-]*flag|grandmasteridentity|logmessageinterval|stepsremoved)\b")


def identity(package, hit):
    data = {"name": package["name"], "version": package["version"], "zip_sha256": package.get("sha256"), "path": hit["path"], "line": hit["line"], "text": hit["text"]}
    return hashlib.sha256(json.dumps(data, ensure_ascii=False, sort_keys=True).encode()).hexdigest()


def main():
    manual_path = DEST / "manual-semantic-dispositions.json"
    manual_bytes = manual_path.read_bytes() if manual_path.exists() else b'{"reviews": []}'
    manual = json.loads(manual_bytes)
    if len({r["source_hit_id"] for r in manual["reviews"]}) != len(manual["reviews"]):
        raise ValueError("Duplicate manual source-hit identities")
    decisions = {row["source_hit_id"]: row for row in manual["reviews"]}
    rows, pending, message_only = [], [], []
    inventory_path, modules_path = BASE / "manifest.json", BASE / "modules.json"
    inventory_bytes, modules_bytes = inventory_path.read_bytes(), modules_path.read_bytes()
    inventory = json.loads(inventory_bytes)
    modules = json.loads(modules_bytes)
    expected = {(m["name"], m["version"]) for m in modules}
    if len(expected) != len(modules):
        raise ValueError("Duplicate name/version pairs in captured module index")
    if hashlib.sha256(modules_bytes).hexdigest() != inventory["index"]["modules_json_sha256"]:
        raise ValueError("Module index hash does not match source inventory")
    processed, specific_message_anchor_hits = 0, 0
    seen, result_snapshot, scanner_versions, source_statuses = set(), [], Counter(), Counter()
    for path in sorted((BASE / "results").glob("*.json")):
        result_bytes = path.read_bytes()
        package = json.loads(result_bytes)
        key = package["name"], package["version"]
        if key not in expected:
            continue
        if key in seen:
            raise ValueError(f"Duplicate current module result: {key}")
        seen.add(key)
        scanner_versions[str(package.get("scanner_version"))] += 1
        source_statuses[str(package.get("status"))] += 1
        result_snapshot.append({"path": str(path.relative_to(ROOT)), "sha256": hashlib.sha256(result_bytes).hexdigest(), "name": key[0], "version": key[1], "scanner_version": package.get("scanner_version"), "status": package.get("status")})
        processed += 1
        for hit in package.get("hits", []):
            specific_message = "ptp_messages" in hit["kinds"] and SPECIFIC_MESSAGE_ANCHOR.search(hit["text"]) is not None
            if specific_message:
                specific_message_anchor_hits += 1
            if set(hit["kinds"]) & STRONG or specific_message:
                ident = identity(package, hit)
                record = {"source_hit_id": ident, "name": package["name"], "version": package["version"], "zip_sha256": package.get("sha256"), "result_file": str(path.relative_to(ROOT)), **hit}
                if ident in decisions:
                    record["manual_review"] = decisions[ident]
                    rows.append(record)
                else:
                    pending.append(record)
            elif "ptp_messages" in hit["kinds"]:
                message_only.append({"name": package["name"], "version": package["version"], **hit, "status": "message_word_without_strong_ptp_anchor; not manually certified by this join"})
    for path, expected_bytes in ((inventory_path, inventory_bytes), (modules_path, modules_bytes), (manual_path, manual_bytes)):
        if path.read_bytes() != expected_bytes:
            raise ValueError(f"Review input changed while joining: {path}")
    for source in result_snapshot:
        if hashlib.sha256((ROOT / source["path"]).read_bytes()).hexdigest() != source["sha256"]:
            raise ValueError(f"Source result changed while joining: {source['path']}")
    complete_current_inventory = inventory.get("final") is True and seen == expected and scanner_versions == {str(inventory.get("scanner_version")): len(expected)} and source_statuses == {"ok": len(expected)}
    result = {"schema": "mooncakes-direct-hit-semantic-review/v2", "scope": "Per-hit manual dispositions for every saved strong PTP/IEEE/BMCA/correction/port-identity lexical hit, plus specialized Delay_Req/Delay_Resp/Pdelay/two-step/Announce field anchors. Word-only follow-up hits are separately retained, not silently certified as reviewed.", "inventory_final": inventory.get("final"), "inventory_statuses": inventory.get("statuses"), "processed_result_files": processed, "expected_modules": len(modules), "scanner_versions": dict(scanner_versions), "complete_current_inventory": complete_current_inventory, "snapshot": {"inventory_sha256": hashlib.sha256(inventory_bytes).hexdigest(), "modules_sha256": hashlib.sha256(modules_bytes).hexdigest(), "manual_reviews_sha256": hashlib.sha256(manual_bytes).hexdigest(), "join_script_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(), "inputs_unchanged_after_join": True, "source_results": result_snapshot}, "summary": {"strong_hits": len(rows) + len(pending), "manually_reviewed": len(rows), "pending_manual_review": len(pending), "specific_message_anchor_hits": specific_message_anchor_hits, "message_word_only_hits": len(message_only), "reviewed_packages": len({r["name"] for r in rows})}, "reviews": rows, "pending": pending, "message_word_only": message_only, "limitations": ["Only downloaded/scanned source and the captured index are covered.", "No lexical detector or per-hit disposition proves absence of all semantic overlap.", "All actual product-capability intersections remain in the separate package classification; a false-positive keyword does not remove those intersections."]}
    DEST.mkdir(parents=True, exist_ok=True)
    (DEST / "full-source-semantic-review.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(result["summary"], ensure_ascii=False))


if __name__ == "__main__":
    main()
