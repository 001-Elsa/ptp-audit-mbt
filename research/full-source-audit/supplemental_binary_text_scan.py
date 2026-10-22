#!/usr/bin/env python3
"""Read-only supplemental keyword inventory of members labelled binary by v4.

Every such member is reread and hashed. Entire, strictly valid UTF-8 files
without NUL or C0/C1 non-text controls are additionally treated as text; valid
UTF-8 with controls is searched as a separate byte-view class. Two
individually identified damaged MoonReduce logs receive a reversible byte view;
this view is explicitly not a claim about their original character encoding.
Main text members over 4 MiB are also checked for complete logical lines over
4 MiB, correcting the main scanner's finite-overlap matching boundary.
No third-party source is executed, imported, compiled, or extracted.
"""
from __future__ import annotations

import argparse
import collections
import concurrent.futures
import datetime
import hashlib
import json
import pathlib
import re
import sys
import tempfile
import zipfile
import codecs
import threading

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
BLOCK_SIZE = 1024 * 1024
LONG_LINE = 4 * 1024 * 1024
LONG_LINE_LOCK = threading.BoundedSemaphore(1)
NON_TEXT = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\x9f]")
IEEE_CONTEXT = re.compile(r"(?i)ieee|ptp|clock|time|协议|同步|1588[-:]20(?:02|08|19)")
MIXED_LOGS = {
    ("Ag108/MoonReduce", "0.2.0", "artifacts/acceptance/final/failures/linux-mounted-verify.log"):
        "0389bd4083153be4eaf4ce00a406461a1793306368e895ace4f0f77f334d3403",
    ("Ag108/MoonReduce", "0.2.0", "artifacts/acceptance/final/platforms/linux-verify.log"):
        "0abe69adbd31bb72d3c3a036cdefef18a3313ab221ab28bf1f2b2706387dc74b",
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha_file(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(BLOCK_SIZE), b""):
            digest.update(block)
    return digest.hexdigest()


def ident(name, version):
    return hashlib.sha256((name + "\0" + version).encode()).hexdigest()


class LineMatcher:
    """Run v4's patterns only once the complete logical line is available.

Long lines retain all content. A lock permits only one worker to accumulate a
line over 4 MiB at a time; small pending lines in other workers remain bounded.
"""

    def __init__(self, patterns, minimum_length=0):
        self.patterns = patterns
        self.minimum_length = minimum_length
        self.parts = []
        self.line_chars = 0
        self.line = 1
        self.hits = []
        self.long_lines = []
        self.max_line_chars = 0
        self.max_line_memory = 0
        self.owns_lock = False

    def match(self, text):
        matches = {name: pattern.search(text) for name, pattern in self.patterns.items()}
        matches = {name: match for name, match in matches.items() if match is not None}
        if "ieee1588_context" in matches and not IEEE_CONTEXT.search(text):
            del matches["ieee1588_context"]
        if not matches:
            return
        first = min(match.start() for match in matches.values())
        start = max(0, first - 160)
        hit = {"line": self.line, "match_column": first + 1,
               "excerpt_start_column": start + 1,
               "kinds": sorted(matches), "text": text[start:start + 800]}
        self.hits.append(hit)

    def append(self, text):
        if text:
            self.parts.append(text)
            self.line_chars += len(text)
        if self.line_chars > LONG_LINE and not self.owns_lock:
            LONG_LINE_LOCK.acquire()
            self.owns_lock = True

    def complete(self):
        try:
            text = "".join(self.parts)
            self.max_line_chars = max(self.max_line_chars, len(text))
            self.max_line_memory = max(self.max_line_memory, sys.getsizeof(text))
            if len(text) > LONG_LINE:
                self.long_lines.append({"line": self.line, "characters": len(text),
                                        "materialized_python_string_bytes": sys.getsizeof(text)})
            if len(text) > self.minimum_length:
                self.match(text)
        finally:
            self.parts = []
            self.line_chars = 0
            if self.owns_lock:
                self.owns_lock = False
                LONG_LINE_LOCK.release()

    def feed(self, text, final=False):
        lines = text.split("\n")
        for part in lines[:-1]:
            self.append(part)
            self.complete()
            self.line += 1
        self.append(lines[-1])
        if final and self.parts:
            self.complete()

    def close(self):
        self.parts = []
        self.line_chars = 0
        if self.owns_lock:
            self.owns_lock = False
            LONG_LINE_LOCK.release()


def scan_member(archive, item, expected, patterns, mixed_key=None):
    matcher = LineMatcher(patterns)
    mixed_matcher = LineMatcher(patterns) if mixed_key in MIXED_LOGS else None
    try:
        return _scan_member_impl(archive, item, expected, patterns, mixed_key, matcher, mixed_matcher)
    finally:
        matcher.close()
        if mixed_matcher is not None:
            mixed_matcher.close()


def _scan_member_impl(archive, item, expected, patterns, mixed_key, matcher, mixed_matcher):
    digest = hashlib.sha256()
    decoder = codecs.getincrementaldecoder("utf-8")(errors="strict")
    mixed_signature = False
    bytes_read = 0
    control_count = 0
    decode_error = None
    byte_roundtrip = True
    with archive.open(item) as stream:
        for block in iter(lambda: stream.read(BLOCK_SIZE), b""):
            digest.update(block)
            if mixed_matcher is not None:
                if bytes_read == 0:
                    mixed_signature = block.startswith(b"w\0s\0l\0:\0") and b"\xef\xbf\xbd" in block
                byte_view = block.decode("latin-1")
                byte_roundtrip = byte_roundtrip and byte_view.encode("latin-1") == block
                mixed_matcher.feed(byte_view)
            if decoder is not None:
                buffered = len(decoder.getstate()[0])
                try:
                    text = decoder.decode(block, final=False)
                except UnicodeDecodeError as error:
                    decode_error = {"byte_offset": bytes_read - buffered + error.start,
                                    "reason": error.reason}
                    decoder = None
                    matcher.close()
                    matcher = None
                else:
                    controls = len(NON_TEXT.findall(text))
                    control_count += controls
                    if matcher is not None:
                        matcher.feed(text)
            bytes_read += len(block)
    if decoder is not None:
        buffered = len(decoder.getstate()[0])
        try:
            tail = decoder.decode(b"", final=True)
        except UnicodeDecodeError as error:
            decode_error = {"byte_offset": bytes_read - buffered + error.start,
                            "reason": error.reason}
            matcher.close()
            matcher = None
        else:
            control_count += len(NON_TEXT.findall(tail))
            if matcher is not None:
                matcher.feed(tail, final=True)
    actual_hash = digest.hexdigest()
    require(bytes_read == expected["bytes"] == item.file_size,
            "binary member byte count: " + item.filename)
    require(actual_hash == expected["sha256"], "binary member SHA-256: " + item.filename)
    strict_utf8 = decode_error is None
    valid_text = strict_utf8 and control_count == 0
    classification = ("strict-utf8-text" if valid_text else
                      "utf8_with_controls_byte_view" if strict_utf8 else "binary")
    record = {"path": item.filename, "bytes": bytes_read, "sha256": actual_hash,
              "original_inventory_kind": "binary", "strict_utf8": strict_utf8,
              "classification": classification,
              "non_text_control_count": control_count if strict_utf8 else None,
              "decode_error": decode_error,
              "max_complete_line_characters": matcher.max_line_chars if matcher is not None else None,
              "max_materialized_line_string_bytes": matcher.max_line_memory if matcher is not None else None,
              "hits": matcher.hits if strict_utf8 and matcher is not None else []}
    if mixed_matcher is not None:
        require(actual_hash == MIXED_LOGS[mixed_key], "identified mixed log changed: " + item.filename)
        require(mixed_signature and byte_roundtrip, "identified mixed log signature/roundtrip")
        require(not valid_text, "identified mixed log unexpectedly became valid UTF-8 text")
        mixed_matcher.feed("", final=True)
        record["mixed_log_byte_view"] = {
            "basis": "Individually inspected WSL log with UTF-16LE-shaped prefix, existing UTF-8 replacement bytes, and ASCII tool output.",
            "method": "Latin-1 is used only as a reversible one-codepoint-per-byte view, not the original text encoding; ASCII protocol spellings remain searchable.",
            "original_encoding_claim": None, "utf16_decoding_attempted": False,
            "byte_roundtrip_verified": byte_roundtrip,
            "boundary": "Cannot restore damaged/non-ASCII text or search Chinese spellings encoded in the mixed prefix.",
            "hits": mixed_matcher.hits,
        }
    return record


def scan_source_nul(archive, item, expected, patterns, reviewed):
    with archive.open(item) as stream:
        raw = stream.read()
    require(len(raw) == expected["bytes"] == item.file_size, "source NUL member size: " + item.filename)
    require(hashlib.sha256(raw).hexdigest() == expected["sha256"] == reviewed["sha256"],
            "source NUL member SHA-256: " + item.filename)
    original = LineMatcher(patterns)
    probe = LineMatcher(patterns)
    try:
        original.feed(raw.decode("utf-8-sig", errors="strict"), final=True)
        view = raw.decode("latin-1").replace("\0", "")
        probe.feed(view, final=True)
    finally:
        original.close()
        probe.close()
    positions = [offset for offset, byte in enumerate(raw) if byte != 0]
    line_starts = [0] + [offset + 1 for offset, char in enumerate(view) if char == "\n"]
    for hit in probe.hits:
        view_offset = line_starts[hit["line"] - 1] + hit["match_column"] - 1
        hit["original_match_byte_offset"] = positions[view_offset]
    record = {"path": item.filename, "bytes": len(raw), "sha256": expected["sha256"],
              "original_inventory_kind": "text", "encoding": expected["encoding"],
              "nul_bytes": raw.count(b"\0"), "strict_utf8_hits": original.hits,
              "nul_stripped_ascii_byte_probe": {
                  "method": "Remove only NUL bytes from a Latin-1 reversible byte view, then search ASCII protocol spellings; this is an exploratory byte probe, not a claim about text encoding or equivalent program behavior.",
                  "offset_basis": "original_match_byte_offset is zero-based in the original archive member",
                  "hits": probe.hits},
              "manual_review": reviewed["manual_review"]}
    manual = reviewed["manual_review"]
    if "tail_start_byte" in manual:
        start = manual["tail_start_byte"]
        tail = raw[start:]
        require(tail.hex() == manual["tail_hex"], "manually inspected mixed README tail changed")
        tail_view = tail.replace(b"\0", b"").decode("ascii", errors="strict")
        tail_matcher = LineMatcher(patterns)
        try:
            tail_matcher.feed(tail_view, final=True)
        finally:
            tail_matcher.close()
        record["identified_mixed_readme_tail"] = {
            "raw_byte_offset": start, "raw_tail_hex": tail.hex(), "nul_stripped_ascii": tail_view,
            "basis": "Individually inspected short duplicated ASCII/NUL project heading, including mixed line terminators; no whole-file UTF-16 claim.",
            "hits": tail_matcher.hits}
    return record


def scan_large_main_text(archive, item, expected, patterns, original_hits):
    decoder = codecs.getincrementaldecoder(expected["encoding"])(errors="strict")
    matcher = LineMatcher(patterns, minimum_length=LONG_LINE)
    digest = hashlib.sha256()
    length = 0
    try:
        with archive.open(item) as stream:
            for block in iter(lambda: stream.read(BLOCK_SIZE), b""):
                digest.update(block)
                length += len(block)
                matcher.feed(decoder.decode(block, final=False))
        matcher.feed(decoder.decode(b"", final=True), final=True)
    finally:
        matcher.close()
    require(length == expected["bytes"] == item.file_size, "large main text size: " + item.filename)
    require(digest.hexdigest() == expected["sha256"], "large main text SHA-256: " + item.filename)
    line_numbers = {line["line"] for line in matcher.long_lines}
    old = [hit for hit in original_hits if hit["path"] == item.filename and hit["line"] in line_numbers]
    old_streamed = [hit for hit in original_hits if hit["path"] == item.filename and hit.get("streamed_long_line")]
    differences = []
    for line in sorted(line_numbers):
        old_kinds = {kind for hit in old if hit["line"] == line for kind in hit["kinds"]}
        new_kinds = {kind for hit in matcher.hits if hit["line"] == line for kind in hit["kinds"]}
        if old_kinds != new_kinds:
            differences.append({"line": line, "added_kinds": sorted(new_kinds - old_kinds),
                                "removed_kinds": sorted(old_kinds - new_kinds)})
    for line in matcher.long_lines:
        line["corrected_hits"] = [hit for hit in matcher.hits if hit["line"] == line["line"]]
        line["main_streamed_hits"] = [hit for hit in old_streamed if hit["line"] == line["line"]]
    return {"path": item.filename, "bytes": length, "sha256": digest.hexdigest(),
            "original_inventory_kind": "text", "encoding": expected["encoding"],
            "long_lines": matcher.long_lines,
            "max_line_characters": matcher.max_line_chars,
            "max_materialized_line_string_bytes": matcher.max_line_memory,
            "corrected_long_line_hits": matcher.hits, "main_hits_on_long_lines": old,
            "main_streamed_hits": old_streamed, "keyword_kind_differences": differences}


def scan_archive(result, binding, cache, patterns, source_nul_targets=None):
    pair = (result["name"], result["version"])
    source_nul_targets = source_nul_targets or {}
    binary_count = sum(record["kind"] == "binary" for record in result["files"])
    large_text_count = sum(record["kind"] == "text" and record["bytes"] > LONG_LINE for record in result["files"])
    if not binary_count and not large_text_count and not source_nul_targets:
        return None
    archive_path = cache / (ident(*pair) + ".zip")
    require(archive_path.stat().st_size == result["archive_bytes"], f"archive size: {pair}")
    require(sha_file(archive_path) == result["sha256"], f"archive SHA-256: {pair}")
    records = []
    large_texts = []
    source_nuls = []
    with zipfile.ZipFile(archive_path) as archive:
        members = [item for item in archive.infolist() if not item.is_dir()]
        require(len(members) == len(result["files"]), f"archive member count: {pair}")
        for item, expected in zip(members, result["files"]):
            require(item.filename == expected["path"], f"archive member path/order: {pair}")
            if expected["kind"] == "binary":
                require(not item.flag_bits & 1, f"encrypted binary member: {pair} {item.filename}")
                records.append(scan_member(archive, item, expected, patterns, (*pair, item.filename)))
            elif expected["bytes"] > LONG_LINE:
                large_texts.append(scan_large_main_text(archive, item, expected, patterns, result["hits"]))
            if item.filename in source_nul_targets:
                require(expected["kind"] == "text" and
                        expected["encoding"] == source_nul_targets[item.filename]["inventory_encoding"],
                        "reviewed source NUL inventory kind/encoding: " + item.filename)
                source_nuls.append(scan_source_nul(archive, item, expected, patterns, source_nul_targets[item.filename]))
    require(len(records) == binary_count == result["binary_files"], f"binary count: {pair}")
    return {"name": pair[0], "version": pair[1], "archive_sha256": result["sha256"],
            "result_file": binding["file"], "result_sha256": binding["sha256"],
            "binary_members": records, "long_line_text_members": large_texts,
            "source_nul_text_members": source_nuls}


def run(args):
    directory = args.directory.resolve()
    manifest_path = directory / "manifest.json"
    manifest_bytes = manifest_path.read_bytes()
    manifest = json.loads(manifest_bytes)
    modules_path = directory / "modules.json"
    modules = json.loads(modules_path.read_bytes())
    pairs = [(module["name"], module["version"]) for module in modules]
    require(len(set(pairs)) == len(pairs), "duplicate current index pairs")
    require(manifest["final"] is True, "main v4 manifest is not frozen/final")
    require(manifest["statuses"] == {"ok": len(pairs), "limited": 0, "unavailable": 0, "error": 0},
            "main scan has incomplete entries")
    require(manifest["unresolved"] == [], "main scan has unresolved entries")
    for field in ("expected_modules", "expected_unique_name_versions", "processed_modules"):
        require(manifest[field] == len(pairs), "main count: " + field)
    bindings = manifest["result_bindings"]
    require([(b["name"], b["version"]) for b in bindings] == pairs, "current result binding order/set")
    index_path = directory / "index.json"
    index = json.loads(index_path.read_bytes())
    require(index == manifest["index"], "main index mismatch")
    raw_path = directory / index["raw_body_file"]
    require(sha_file(raw_path) == index["raw_sha256"], "raw index SHA-256")
    require(json.loads(raw_path.read_bytes()) == modules, "raw/pretty parse mismatch")
    require(sha_file(modules_path) == manifest["modules_json_sha256"] == index["modules_json_sha256"],
            "pretty index SHA-256")
    scanner_path = ROOT / "scripts/audit_all_mooncakes_sources.py"
    config_path = directory / "encoding-overrides.json"
    require(sha_file(scanner_path) == manifest["scanner_sha256"], "main scanner SHA-256")
    require(sha_file(config_path) == manifest["encoding_overrides_sha256"], "encoding config SHA-256")
    frozen_paths = {manifest_path: hashlib.sha256(manifest_bytes).hexdigest(),
                    index_path: sha_file(index_path), raw_path: index["raw_sha256"],
                    modules_path: manifest["modules_json_sha256"],
                    scanner_path: manifest["scanner_sha256"],
                    config_path: manifest["encoding_overrides_sha256"]}
    self_path = pathlib.Path(__file__).resolve()
    frozen_paths[self_path] = sha_file(self_path)
    nul_review_path = directory / "text-source-nul-review.json"
    frozen_paths[nul_review_path] = sha_file(nul_review_path)
    nul_review = json.loads(nul_review_path.read_bytes())
    require(nul_review["result"] == "pass" and nul_review["errors"] == [] and
            nul_review["changed_result_files"] == [], "source NUL review is incomplete")
    require(nul_review["completed_results"] == nul_review["index_modules"] == len(pairs) and
            nul_review["not_yet_v4_ok"] == [], "source NUL review does not cover the frozen current scope")
    require(nul_review["modules_json_sha256"] == manifest["modules_json_sha256"] and
            nul_review["main_scanner_sha256"] == manifest["scanner_sha256"], "source NUL review identity")
    source_nul_targets = {}
    bom_nul_covered = []
    nul_review_archives = {(archive["name"], archive["version"]): archive for archive in nul_review["archives"]}
    require(set(nul_review_archives) == set(pairs) and len(nul_review_archives) == len(nul_review["archives"]),
            "source NUL review current archive set")
    for archive in nul_review["archives"]:
        pair = (archive["name"], archive["version"])
        for record in archive["nul_members"]:
            if record["inventory_encoding"] in ("utf-16", "utf-32"):
                require(record["bom"] is not None, "NUL source declared UTF-16/32 without a reviewed BOM")
                bom_nul_covered.append({"name": pair[0], "version": pair[1], "path": record["path"],
                                        "sha256": record["sha256"], "encoding": record["inventory_encoding"]})
            else:
                require(record["strict_decoding_checks"]["utf-8"]["valid"] is True and
                        "manual_review" in record, "NUL source requires explicit encoding/manual review")
                source_nul_targets.setdefault(pair, {})[record["path"]] = record
    patterns = {name: re.compile(pattern) for name, pattern in manifest["keyword_patterns"].items()}
    require(set(patterns) == {"ptp_protocol", "ieee1588_context", "bmca", "correction_field",
                              "port_identity", "ptp_messages", "clock_sync", "protocol_capture_audit",
                              "request_response_deadline"}, "unexpected keyword rule set")
    results = []
    expected_binary = 0
    expected_long_line_candidates = 0
    expected_mixed = set()
    for binding in bindings:
        pair = (binding["name"], binding["version"])
        require(binding["file"] == "results/" + ident(*pair) + ".json", f"result binding path: {pair}")
        path = directory / binding["file"]
        require(sha_file(path) == binding["sha256"], f"result binding SHA-256: {pair}")
        frozen_paths[path] = binding["sha256"]
        result = json.loads(path.read_bytes())
        require(nul_review_archives[pair]["result_sha256"] == binding["sha256"],
                "source NUL review result binding: " + str(pair))
        require((result["name"], result["version"]) == pair, f"result pair: {pair}")
        require(result["scanner_sha256"] == manifest["scanner_sha256"] and
                result["scanner_version"] == manifest["scanner_version"], f"result scanner: {pair}")
        require(result["status"] == "ok" and result["limitations"] == [], f"result status: {pair}")
        require(all(record["kind"] in ("text", "binary") for record in result["files"]), f"member kind: {pair}")
        expected_binary += result["binary_files"]
        expected_long_line_candidates += sum(record["kind"] == "text" and record["bytes"] > LONG_LINE for record in result["files"])
        for record in result["files"]:
            if (*pair, record["path"]) in MIXED_LOGS:
                require(record["kind"] == "binary", "known mixed log was reclassified in main inventory")
                expected_mixed.add((*pair, record["path"]))
        results.append(result)
    require(expected_mixed == set(MIXED_LOGS), "the two identified damaged logs are absent from this captured scope")
    cache = args.cache.resolve() if args.cache else pathlib.Path(manifest["cache"])
    archives = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        jobs = [pool.submit(scan_archive, result, binding, cache, patterns,
                            source_nul_targets.get((result["name"], result["version"]), {}))
                for result, binding in zip(results, bindings)]
        for i, future in enumerate(concurrent.futures.as_completed(jobs), 1):
            archive = future.result()
            if archive is not None:
                archives.append(archive)
            if i % 250 == 0 or i == len(jobs):
                print(json.dumps({"processed_results": i, "expected": len(jobs),
                                  "archives_with_additional_checks": len(archives)}), flush=True)
    archives.sort(key=lambda archive: (archive["name"], archive["version"]))
    records = [record for archive in archives for record in archive["binary_members"]]
    long_line_records = [record for archive in archives for record in archive["long_line_text_members"]]
    source_nul_records = [record for archive in archives for record in archive["source_nul_text_members"]]
    require(len(records) == expected_binary, "supplemental binary member count")
    require(len(long_line_records) == expected_long_line_candidates, "supplemental long-line candidate count")
    require(len(source_nul_records) == sum(len(records) for records in source_nul_targets.values()),
            "supplemental source NUL target count")
    actual_mixed = {((archive["name"], archive["version"], record["path"]))
                    for archive in archives for record in archive["binary_members"]
                    if "mixed_log_byte_view" in record}
    require(actual_mixed == expected_mixed, "supplemental identified mixed log set")
    for path, expected in frozen_paths.items():
        require(sha_file(path) == expected, "bound input changed during supplemental scan: " + str(path))
    classes = collections.Counter(record["classification"] for record in records)
    mixed_records = [record for record in records if "mixed_log_byte_view" in record]
    return {"schema": "mooncakes-binary-text-supplement/v1", "result": "pass",
            "limitations": [], "unresolved": [],
            "checked_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "supplemental_scanner_sha256": frozen_paths[self_path],
            "main_manifest_sha256": frozen_paths[manifest_path],
            "main_scanner_sha256": manifest["scanner_sha256"],
            "main_scanner_version": manifest["scanner_version"],
            "index_raw_sha256": index["raw_sha256"], "index_pretty_sha256": manifest["modules_json_sha256"],
            "encoding_overrides_sha256": manifest["encoding_overrides_sha256"],
            "source_nul_review_sha256": frozen_paths[nul_review_path],
            "expected_modules": len(pairs), "verified_result_bindings": len(bindings),
            "archives_with_binary_members": sum(bool(archive["binary_members"]) for archive in archives),
            "archives_with_additional_checks": len(archives),
            "binary_members_expected": expected_binary, "binary_members_read_and_hashed": len(records),
            "binary_member_bytes_read": sum(record["bytes"] for record in records),
            "classifications": dict(classes),
            "strict_utf8_text_hit_files": sum(record["classification"] == "strict-utf8-text" and bool(record["hits"]) for record in records),
            "utf8_control_view_hit_files": sum(record["classification"] == "utf8_with_controls_byte_view" and bool(record["hits"]) for record in records),
            "identified_mixed_logs": len(mixed_records),
            "identified_mixed_log_hit_files": sum(bool(record["mixed_log_byte_view"]["hits"]) for record in mixed_records),
            "long_line_candidate_files_expected": expected_long_line_candidates,
            "long_line_candidate_files_checked": len(long_line_records),
            "long_lines_found": sum(len(record["long_lines"]) for record in long_line_records),
            "long_line_hits": sum(len(record["corrected_long_line_hits"]) for record in long_line_records),
            "long_line_keyword_kind_difference_files": sum(bool(record["keyword_kind_differences"]) for record in long_line_records),
            "source_nul_files_expected": sum(len(records) for records in source_nul_targets.values()),
            "source_nul_files_checked": len(source_nul_records),
            "source_nul_ascii_probe_hit_files": sum(bool(record["nul_stripped_ascii_byte_probe"]["hits"]) for record in source_nul_records),
            "identified_mixed_readme_tails": sum("identified_mixed_readme_tail" in record for record in source_nul_records),
            "bom_utf16_nul_members_already_covered": bom_nul_covered,
            "max_materialized_line_string_bytes": max([record.get("max_materialized_line_string_bytes") or 0 for record in records + long_line_records], default=0),
            "keyword_patterns": manifest["keyword_patterns"],
            "text_policy": "An entire member must strictly decode as UTF-8. With no NUL or C0/C1 control except TAB/LF/CR it is strict-utf8-text; otherwise it is searched under utf8_with_controls_byte_view, not labelled ordinary text. Invalid UTF-8 remains binary. No automatic UTF-16 guessing.",
            "matching_policy": "Same keyword patterns and IEEE-1588 numeric-context filter as main v4, evaluated only on a complete logical line; no line content truncation. Main text files over 4 MiB are fully decoded using their recorded encoding, and only lines over 4 MiB are rematched.",
            "memory_policy": "One line over 4 MiB may accumulate across workers at a time. Complete-line content is retained; reported string size excludes the parts list, temporary copies and interpreter overhead.",
            "checks": ["all current result bindings, scanner, configuration and index hashes",
                       "every archive containing binary members rehashed",
                       "every original binary member reread to EOF, CRC checked by zipfile, byte count and SHA-256 checked",
                       "whole-file strict UTF-8 and non-text control classification",
                       "all main text members over 4 MiB hashed and fully decoded; complete long lines rematched against exact patterns",
                       "only individually hash-pinned damaged logs receive a reversible byte view",
                       "all explicitly reviewed UTF-8 source NUL members rehashed and searched, with separately labelled NUL-stripped ASCII byte probes",
                       "all bound input files unchanged at completion"],
            "boundary": "This supplements binary classification and long-line matching without changing the v4 manifest, encoding overrides or results. Archives are hashed before member reads; members are hashed while read. It does not assert semantic originality, recover damaged text, decode arbitrary binaries as UTF-16, or cover unlisted/historical versions.",
            "result_bindings": bindings, "archives": archives}


def self_test():
    patterns = {"ptp_protocol": re.compile(r"(?i)\bptp|精确时间协议"),
                "correction_field": re.compile(r"(?i)correction[ _-]*field"),
                "ieee1588_context": re.compile(r"\b1588\b")}
    fixtures = {
        "text.dat": b"PtpHeader correction_field\n",
        "plain.bin": b"hello",
        "chinese.dat": "精确时间协议\n".encode(),
        "invalid.bin": b"\xff PTP",
        "invalid_tail.bin": b"PTP\n" + b"a" * BLOCK_SIZE + b"\xff",
        "nul.bin": b"PTP\0",
        "utf16.bin": "ptp".encode("utf-16le"),
        "c1.bin": "PTP\u0085".encode(),
        "empty.bin": b"",
        "boundary.bin": b"a" * (BLOCK_SIZE - 1) + "精确时间协议\n".encode(),
        "long.dat": (b"x" * (LONG_LINE + BLOCK_SIZE - 2) + b" PTP correction-field"
                     + b"x" * (BLOCK_SIZE + 32) + b"\n"),
    }
    with tempfile.TemporaryDirectory(prefix="ptp-binary-text-self-test-") as directory:
        path = pathlib.Path(directory) / "fixtures.zip"
        with zipfile.ZipFile(path, "w") as archive:
            for name, content in fixtures.items():
                archive.writestr(name, content)
        with zipfile.ZipFile(path) as archive:
            records = {}
            for item in archive.infolist():
                content = fixtures[item.filename]
                expected = {"bytes": len(content), "sha256": hashlib.sha256(content).hexdigest()}
                records[item.filename] = scan_member(archive, item, expected, patterns)
            for name in ("text.dat", "plain.bin", "chinese.dat", "empty.bin", "boundary.bin", "long.dat"):
                require(records[name]["classification"] == "strict-utf8-text", "self-test valid text " + name)
            for name in ("invalid.bin", "invalid_tail.bin"):
                require(records[name]["classification"] == "binary" and not records[name]["hits"], "self-test binary " + name)
            for name in ("nul.bin", "utf16.bin", "c1.bin"):
                require(records[name]["classification"] == "utf8_with_controls_byte_view", "self-test control view " + name)
            for name in ("text.dat", "chinese.dat", "boundary.bin", "long.dat"):
                require(bool(records[name]["hits"]), "self-test keyword " + name)
            require(bool(records["nul.bin"]["hits"]) and bool(records["c1.bin"]["hits"]), "self-test control matching")
            require(not records["utf16.bin"]["hits"], "self-test no UTF16 guessing")
            require(not records["plain.bin"]["hits"], "self-test plain fixture")
            require(records["long.dat"]["hits"][0]["match_column"] == LONG_LINE + BLOCK_SIZE,
                    "self-test keyword crossing rolling-window boundary and absolute column")
            require(records["invalid.bin"]["decode_error"]["byte_offset"] == 0, "self-test invalid offset")
            require(records["invalid_tail.bin"]["decode_error"]["byte_offset"] == BLOCK_SIZE + 4,
                    "self-test invalid tail offset and discarded provisional hits")
            item = archive.getinfo("plain.bin")
            try:
                scan_member(archive, item, {"bytes": 5, "sha256": "0" * 64}, patterns)
            except ValueError:
                pass
            else:
                raise ValueError("self-test must reject mismatched expected member hash")
            large_record = scan_large_main_text(archive, archive.getinfo("long.dat"),
                                               {"bytes": len(fixtures["long.dat"]),
                                                "sha256": hashlib.sha256(fixtures["long.dat"]).hexdigest(),
                                                "encoding": "utf-8"}, patterns, [])
            require(len(large_record["long_lines"]) == 1 and bool(large_record["corrected_long_line_hits"]),
                    "self-test main large-text correction")
    actual_patterns = {name: re.compile(pattern) for name, pattern in
                       json.loads((HERE / "manifest.json").read_text())["keyword_patterns"].items()}
    probes = [
        ("unbounded-separator", "correction" + " " * (LONG_LINE + 1), "field\n", "correction_field", True),
        ("future-right-boundary", "x" * (LONG_LINE + 1) + " ptp", "notaprotocol\n", "ptp_protocol", False),
        ("whole-line-IEEE-context", "1588" + " " * (LONG_LINE + 1), "IEEE\n", "ieee1588_context", True),
    ]
    for name, first, last, kind, expected_hit in probes:
        matcher = LineMatcher(actual_patterns)
        try:
            matcher.feed(first)
            require(not matcher.hits, "self-test must defer unfinished logical line: " + name)
            matcher.feed(last, final=True)
            require(any(kind in hit["kinds"] for hit in matcher.hits) is expected_hit,
                    "self-test exact complete-line rule: " + name)
        finally:
            matcher.close()
    return {"result": "pass", "self_test_fixtures": len(fixtures),
            "whole_line_regression_probes": len(probes),
            "supplemental_scanner_sha256": sha_file(pathlib.Path(__file__)),
            "checks": ["strict UTF-8", "separate NUL/C0/C1 byte-view classification/matching", "no generic UTF-16 decoding",
                       "UTF-8 sequence crossing read boundary", "invalid final block discards provisional hits",
                       "complete long line matching and main-text correction",
                       "real-rule unbounded separator, future word boundary and whole-line IEEE context",
                       "per-member hash/size and mismatched hash rejection"]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=pathlib.Path, default=HERE)
    parser.add_argument("--cache", type=pathlib.Path)
    parser.add_argument("--workers", type=int, default=8)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    require(1 <= args.workers <= 24, "workers must be between 1 and 24")
    try:
        output = self_test() if args.self_test else run(args)
    except (ValueError, KeyError, OSError, zipfile.BadZipFile) as error:
        print(json.dumps({"result": "fail", "error": str(error)}), file=sys.stderr)
        return 1
    if not args.self_test:
        target = args.directory / "supplemental-binary-text.json"
        temporary = target.with_suffix(target.suffix + ".tmp")
        temporary.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n")
        temporary.replace(target)
    print(json.dumps({key: value for key, value in output.items() if key not in ("archives", "result_bindings", "keyword_patterns")}, ensure_ascii=False), flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
