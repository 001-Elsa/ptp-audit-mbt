#!/usr/bin/env python3
"""Read-only, reproducible MoonBit source-clone screening of saved registry ZIPs.

This is a candidate detector, not a uniqueness certificate or semantic plagiarism
oracle. It never imports, extracts, builds or executes third-party source. Each
ZIP must match the SHA-256 in the supplied dated audit before it is inspected.
"""

from __future__ import annotations

import argparse
import bisect
import hashlib
import json
import re
import tempfile
import zipfile
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_AUDIT = ROOT / "research/2026-10-19-release-review/source-audit.json"
DEFAULT_OUTPUT = ROOT / "research/originality-completion/source-clone-screen.json"
TOKEN = re.compile(
    r'(?P<comment>//[^\n]*|/\*[\s\S]*?\*/)'
    r'|(?P<string>#\|[^\n]*|\$?"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\')'
    r'|(?P<id>[^\W\d]\w*)'
    r'|(?P<number>\d[\w.]*)'
    r'|(?P<op>=>|->|::|\.\.=|\.\.|==|!=|<=|>=|&&|\|\||<<|>>|[^\s])',
    re.UNICODE,
)
KEYWORDS = set(
    "pub priv all struct enum trait type typealias fn let mut const if else match "
    "guard while for in continue break return raise try catch derive async extern "
    "impl import as is true false test init loop with do not readonly recur defer "
    "Int Int32 Int64 UInt UInt32 UInt64 Int16 UInt16 Byte Bool Char String Bytes "
    "StringView Unit Float Double Array FixedArray ArrayView Map Set Option Result "
    "Some None Ok Err Show Debug Eq Compare Hash Default Iterator".split()
)
MASK = (1 << 64) - 1
BASE = 1_000_003


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def file_digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


DETECTOR_FILE = Path(__file__).resolve()
LOADED_DETECTOR_SHA256 = file_digest(DETECTOR_FILE)


def source_rows(audit: Path, saved_bytes: bytes):
    data = json.loads(saved_bytes)
    if isinstance(data, list):
        return data, None
    if data.get("schema") != "mooncakes-full-source-scan/v1":
        raise ValueError("Unrecognized source-audit schema")
    index_bytes = (audit.parent / "modules.json").read_bytes()
    index_sha256 = digest(index_bytes)
    recorded_index_sha256 = data.get("index", {}).get("modules_json_sha256")
    if recorded_index_sha256 is not None and index_sha256 != recorded_index_sha256:
        raise ValueError("Source index differs from the hash recorded in the audit manifest")
    index = json.loads(index_bytes)
    keys = [(module["name"], module["version"]) for module in index]
    if len(keys) != len(set(keys)):
        raise ValueError("Source index contains duplicate name/version rows")
    available = {}
    for path in sorted((audit.parent / "results").glob("*.json")):
        row_bytes = path.read_bytes()
        row = json.loads(row_bytes)
        key = (row["name"], row["version"])
        if key in available:
            raise ValueError(f"Duplicate source-result metadata for {key}")
        available[key] = {
            key: row.get(key)
            for key in ("name", "version", "status", "error", "limitations", "cache_file", "sha256")
        }
        available[key].update(source_result_file=str(path.relative_to(audit.parent)), source_result_sha256=digest(row_bytes))
    rows = []
    result_snapshots = []
    for key in keys:
        row = available.get(key)
        if row is None:
            rows.append({"name": key[0], "version": key[1], "status": "not_available_in_saved_audit"})
        else:
            rows.append({**row, "evidence_file": row.get("cache_file")})
        result_snapshots.append({"name": key[0], "version": key[1], "source_result_file": row.get("source_result_file") if row else None, "source_result_sha256": row.get("source_result_sha256") if row else None})
    metadata_sha256 = digest(json.dumps(result_snapshots, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode())
    return rows, {"schema": data["schema"], "final": data.get("final"), "expected_modules": len(index), "index_sha256": index_sha256, "result_metadata_snapshot_sha256": metadata_sha256}


def tokens(text: str) -> list[tuple[str, int, str]]:
    newlines = [m.start() for m in re.finditer("\n", text)]
    return [
        (m.group(), bisect.bisect_left(newlines, m.start()) + 1, m.lastgroup)
        for m in TOKEN.finditer(text)
        if m.lastgroup != "comment"
    ]


def canonical_block(part: list[tuple[str, int, str]]) -> tuple[str, ...]:
    """Normalize consistently renamed identifiers; retain literals and keywords."""
    names = {}
    result = []
    for value, _, kind in part:
        if kind == "id" and value not in KEYWORDS:
            if value not in names:
                names[value] = f"$id{len(names)}"
            value = names[value]
        result.append(value)
    return tuple(result)


def blocks(text: str):
    """MoonBit's explicit block delimiter gives stable, auditable boundaries."""
    cuts = [0] + [m.end() for m in re.finditer(r"(?m)^///\|[^\n]*\n", text)]
    cuts.append(len(text))
    cuts = sorted(set(cuts))
    for start, end in zip(cuts, cuts[1:]):
        part = tokens(text[start:end])
        offset = text.count("\n", 0, start)
        if part:
            yield [(value, line + offset, kind) for value, line, kind in part]


def gram_hashes(values: list[int], width: int):
    if len(values) < width:
        return
    power = pow(BASE, width - 1, 1 << 64)
    running = 0
    for value in values[:width]:
        running = (running * BASE + value) & MASK
    yield 0, running
    for pos in range(1, len(values) - width + 1):
        running = ((running - values[pos - 1] * power) * BASE + values[pos + width - 1]) & MASK
        yield pos, running


def is_test(path: str) -> bool:
    return path.endswith(("_test.mbt", "_wbtest.mbt")) or "/tests/" in "/" + path


def generated_reason(path: str, text: str) -> str | None:
    """Only an explicit generation declaration in the actual leading comments.

    A string literal or an ordinary "do not edit" instruction is insufficient.
    Stop at the first line of code, so an example inside a function cannot
    accidentally exclude the production file.
    """
    header = []
    in_block = False
    for line in text[:8192].splitlines():
        value = line.strip()
        if not value or value == "///|":
            continue
        if value.startswith("///"):
            # Documentation examples are not file-generation declarations.
            # The inclusive final pass still scans every generated file.
            continue
        if in_block:
            before, marker, after = value.partition("*/")
            header.append(before.lstrip("* "))
            if marker:
                in_block = False
                if after.strip():
                    break
        elif value.startswith("//"):
            header.append(value.lstrip("/ "))
        elif value.startswith("/*"):
            before, marker, after = value[2:].partition("*/")
            header.append(before.lstrip("* "))
            in_block = not bool(marker)
            if marker and after.strip():
                break
        else:
            break
    declaration = re.compile(
        r"(?im)^\s*(?:@generated\b|code generated\b|"
        r"(?:this (?:file|source) (?:is|was) )?(?:auto[- ]generated|automatically generated)\b|"
        r"generated (?:by|from|using|with)\b)"
    )
    for comment in header:
        if declaration.search(comment):
            return comment[:300]
    return None


def local_sources():
    excluded = {"research", "_build", "target", ".mooncakes", ".git"}
    for path in sorted(ROOT.rglob("*.mbt")):
        rel = path.relative_to(ROOT)
        if any(part in excluded for part in rel.parts) or is_test(str(rel)):
            continue
        data = path.read_bytes()
        yield str(rel), data.decode("utf8"), digest(data)


def decode_source(data: bytes) -> str:
    """Decode source strictly, honoring a UTF-16/32 BOM before UTF-8.

    A source file with a BOM is still source; treating it as an invalid UTF-8
    exclusion would silently narrow the otherwise inclusive foreign scan.
    """
    if data.startswith((b"\xff\xfe\x00\x00", b"\x00\x00\xfe\xff")):
        return data.decode("utf-32")
    if data.startswith((b"\xff\xfe", b"\xfe\xff")):
        return data.decode("utf-16")
    return data.decode("utf-8-sig")


def screen(audit: Path, output: Path, minimum: int, minimum_lines: int, include_generated: bool = False, max_source_bytes: int = 32 * 1024 * 1024, include_tests: bool = False, progress_every: int = 0, shard_count: int = 1, shard_index: int = 0):
    if file_digest(DETECTOR_FILE) != LOADED_DETECTOR_SHA256:
        raise ValueError("Detector source changed after loading; rerun the original snapshot")
    audit_snapshot = audit.read_bytes()
    rows, source_inventory = source_rows(audit, audit_snapshot)
    original_expected = len(rows)
    rows = [row for index, row in enumerate(rows) if index % shard_count == shard_index]
    local = list(local_sources())
    symbols: dict[str, int] = {}

    def encode(parts):
        result = []
        for value in parts:
            if value not in symbols:
                symbols[value] = len(symbols) + 1
            result.append(symbols[value])
        return result

    seed_width = min(32, minimum)
    exact_index = defaultdict(list)
    block_index = defaultdict(list)
    local_tokens = []
    for index, (path, text, _) in enumerate(local):
        part = tokens(text)
        local_tokens.append(part)
        for pos, h in gram_hashes(encode([value for value, _, _ in part]), seed_width):
            exact_index[h].append((index, pos))
        for block in blocks(text):
            if len(block) >= minimum and block[-1][1] - block[0][1] + 1 >= minimum_lines:
                block_index[canonical_block(block)].append((index, block[0][1], block[-1][1]))

    matches = []
    packages = []
    skipped = []
    unresolved_packages = []
    inventory_limitations = []
    seen = set()
    for row in rows:
        if row.get("status") not in {"ok", "limited"}:
            unresolved_packages.append({"name": row["name"], "version": row["version"], "status": row.get("status"), "reason": row.get("error"), "limitations": row.get("limitations"), "source_result_file": row.get("source_result_file"), "source_result_sha256": row.get("source_result_sha256")})
            continue
        if row.get("status") == "limited":
            inventory_limitations.append({"name": row["name"], "version": row["version"], "status": "limited", "limitations": row.get("limitations"), "treatment": "ZIP is available; scan all eligible MoonBit files independently while retaining upstream all-text limitations"})
        archive = ROOT / row["evidence_file"]
        if file_digest(archive) != row["sha256"]:
            raise ValueError(f"Source ZIP hash mismatch: {archive}")
        counts = {"moonbit_files": 0, "production_files": 0, "scanned_files": 0, "test_files": 0, "generated_files": 0, "tokens": 0}
        with zipfile.ZipFile(archive) as z:
            for info in sorted(z.infolist(), key=lambda f: f.filename):
                path = info.filename
                if info.is_dir() or not path.endswith(".mbt"):
                    continue
                counts["moonbit_files"] += 1
                if info.file_size > max_source_bytes:
                    skipped.append({"package": row["name"], "version": row["version"], "path": path, "bytes": info.file_size, "reason": f"file exceeds explicit {max_source_bytes}-byte safety bound"})
                    continue
                try:
                    text = decode_source(z.read(info))
                except UnicodeDecodeError:
                    skipped.append({"package": row["name"], "version": row["version"], "path": path, "reason": "not valid UTF-8 or BOM-declared UTF-16/32 source"})
                    continue
                test_source = is_test(path)
                if test_source:
                    counts["test_files"] += 1
                    if not include_tests:
                        continue
                reason = generated_reason(path, text)
                if reason:
                    counts["generated_files"] += 1
                    if not include_generated:
                        skipped.append({"package": row["name"], "version": row["version"], "path": path, "bytes": info.file_size, "reason": "explicit leading-comment generation declaration: " + reason})
                        continue
                counts["production_files"] += int(not test_source)
                counts["scanned_files"] += 1
                part = tokens(text)
                counts["tokens"] += len(part)
                values = [value for value, _, _ in part]
                covered = {}
                # Unknown foreign tokens cannot participate in an exact local
                # match. Do not retain the entire ecosystem's symbol table.
                for pos, h in gram_hashes([symbols.get(value, 0) for value in values], seed_width):
                    for index, other_pos in exact_index.get(h, ()):
                        diagonal = (index, other_pos - pos)
                        if covered.get(diagonal, -1) >= pos + seed_width:
                            continue
                        other = local_tokens[index]
                        if values[pos:pos + seed_width] != [v for v, _, _ in other[other_pos:other_pos + seed_width]]:
                            continue
                        start, other_start = pos, other_pos
                        while start and other_start and part[start - 1][0] == other[other_start - 1][0]:
                            start -= 1
                            other_start -= 1
                        end, other_end = pos + seed_width, other_pos + seed_width
                        while end < len(part) and other_end < len(other) and part[end][0] == other[other_end][0]:
                            end += 1
                            other_end += 1
                        covered[diagonal] = end
                        line_count = other[other_end - 1][1] - other[other_start][1] + 1
                        if end - start < minimum or line_count < minimum_lines:
                            continue
                        key = ("exact_tokens", row["name"], row["version"], index, path, other_start, other_end, start, end)
                        if key in seen:
                            continue
                        seen.add(key)
                        matches.append({"kind": "exact_tokens", "package": row["name"], "version": row["version"], "external_path": path, "external_lines": [part[start][1], part[end - 1][1]], "local_path": local[index][0], "local_lines": [other[other_start][1], other[other_end - 1][1]], "tokens": end - start, "disposition": "manual_review_required"})
                for block in blocks(text):
                    if len(block) < minimum or block[-1][1] - block[0][1] + 1 < minimum_lines:
                        continue
                    for index, first, last in block_index.get(canonical_block(block), ()):
                        key = ("consistent_identifier_rename_block", row["name"], row["version"], index, path, first, last, block[0][1], block[-1][1])
                        if key in seen:
                            continue
                        seen.add(key)
                        matches.append({"kind": key[0], "package": row["name"], "version": row["version"], "external_path": path, "external_lines": [block[0][1], block[-1][1]], "local_path": local[index][0], "local_lines": [first, last], "tokens": len(block), "disposition": "manual_review_required"})
        packages.append({"name": row["name"], "version": row["version"], "source_inventory_status": row.get("status"), "zip_sha256": row["sha256"], "evidence_file": row["evidence_file"], "source_result_file": row.get("source_result_file"), "source_result_sha256": row.get("source_result_sha256"), **counts, "candidate_matches": sum(m["package"] == row["name"] and m["version"] == row["version"] for m in matches)})
        if progress_every and len(packages) % progress_every == 0:
            print(json.dumps({"phase": "source_clone_screen", "packages_scanned": len(packages), "expected_packages": len(rows), "unresolved_packages": len(unresolved_packages), "external_tokens": sum(p["tokens"] for p in packages), "candidate_matches": len(matches), "latest": row["name"]}, ensure_ascii=False), flush=True)

    result = {
        "schema": "ptp-source-clone-screen/v1",
        "purpose": "Bounded source-clone candidate detection, not an absolute non-similarity certificate",
        "audit": str(audit.relative_to(ROOT)),
        "audit_sha256": digest(audit_snapshot),
        "detector_sha256": LOADED_DETECTOR_SHA256,
        "source_inventory": source_inventory,
        "shard": {"index": shard_index, "count": shard_count, "expected_all_packages": original_expected, "assigned_packages": len(rows)},
        "method": {"exact": "Comments and whitespace removed; all identifiers, literals and operators preserved. Every matching seed is extended maximally and collision-verified.", "renamed": "Complete ///| blocks with consistently bijective identifier renaming; reserved keywords, listed built-in type names and literals retained. User-defined type names are normalized with other identifiers.", "minimum_tokens": minimum, "minimum_local_source_span_lines": minimum_lines, "minimum_foreign_source_span_lines_for_renamed_blocks": minimum_lines, "seed_tokens": seed_width, "include_generated": include_generated, "include_foreign_tests": include_tests, "max_source_bytes": max_source_bytes, "excluded": "Local tests, interfaces, non-MoonBit files and snippets below thresholds. Foreign tests excluded only when include_foreign_tests=false; generated files excluded only when include_generated=false and leading comments explicitly declare generation.", "source_decoding": "Strict UTF-8 with optional BOM; BOM-declared UTF-16/32 decoded strictly. Other invalid source bytes remain explicit exclusions.", "third_party_code_executed": False},
        "local_sources": [{"path": path, "sha256": sha, "tokens": len(local_tokens[i])} for i, (path, _, sha) in enumerate(local)],
        "packages": packages,
        "summary": {"packages": len(packages), "unresolved_packages": len(unresolved_packages), "limited_source_inventories": len(inventory_limitations), "expected_packages": len(rows), "local_files": len(local), "local_tokens": sum(len(p) for p in local_tokens), "external_production_files": sum(p["production_files"] for p in packages), "external_scanned_files": sum(p["scanned_files"] for p in packages), "external_tokens": sum(p["tokens"] for p in packages), "candidate_matches": len(matches), "identified_generated_files": sum(p["generated_files"] for p in packages), "excluded_generated_files": 0 if include_generated else sum(p["generated_files"] for p in packages), "identified_test_files": sum(p["test_files"] for p in packages), "excluded_test_files": 0 if include_tests else sum(p["test_files"] for p in packages)},
        "candidate_matches": matches,
        "explicit_exclusions": skipped,
        "unresolved_packages": unresolved_packages,
        "source_inventory_limitations": inventory_limitations,
        "limitations": ["Coverage is the available version-pinned source collection and explicit exclusions in this result, not all history or unpublished Mooncakes code.", "This lexical scanner is not a complete MoonBit parser; unusual string/comment syntax and unsupported constructs require manual review.", "Semantic equivalence, reordered or substantially edited code, subthreshold snippets, comments, other languages and unpublished/history versions are not proven absent.", "A candidate is not plagiarism; attribution, standard algorithms and source history require human review.", "No candidate does not establish absolute source originality or contest eligibility."],
    }
    if file_digest(DETECTOR_FILE) != LOADED_DETECTOR_SHA256:
        raise ValueError("Detector source changed during screening; rerun against a frozen snapshot")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(result["summary"], ensure_ascii=False))
    return result


def self_test():
    global ROOT
    for encoding in ("utf-8", "utf-8-sig", "utf-16", "utf-32"):
        assert decode_source('fn 中文() { "source" }'.encode(encoding)) == 'fn 中文() { "source" }'
    try:
        decode_source(b"\xffinvalid")
    except UnicodeDecodeError:
        pass
    else:
        raise AssertionError("Invalid source bytes must remain an explicit exclusion")
    assert [v for v, _, _ in tokens('let x = "// retained" // removed\n')] == ["let", "x", "=", '"// retained"']
    left = tokens('fn add(x : Int) -> Int { x + 1 }')
    renamed = tokens('fn plus(y : Int) -> Int { y + 1 }')
    different = tokens('fn plus(y : Int) -> Int { y + 2 }')
    inconsistent = tokens('fn plus(y : Int) -> Int { z + 1 }')
    assert canonical_block(left) == canonical_block(renamed)
    assert canonical_block(left) != canonical_block(different)
    assert canonical_block(left) != canonical_block(inconsistent)
    assert generated_reason("case.mbt", 'let value = "automatically generated; do not edit"') is None
    assert generated_reason("case.mbt", '// Do not edit this API casually.\npub fn hand_written() { () }') is None
    assert generated_reason("case.mbt", 'pub fn hand_written() {\n // Generated by an example\n ()\n}') is None
    assert generated_reason("case.mbt", '/// Example:\n/// // Generated by a sample command\npub fn hand_written() { () }') is None
    assert generated_reason("case.mbt", '///|\n// Generated by an actual code generator; do not edit.\npub fn generated() { () }') is not None
    values = [2, 6, 3, 1, 0, 7]
    observed = list(gram_hashes(values, 3))
    for start, h in observed:
        expected = 0
        for value in values[start:start + 3]:
            expected = (expected * BASE + value) & MASK
        assert h == expected
    assert len(list(blocks('///|\nfn a() { 1 }\n///|\nfn b() { 2 }'))) == 2
    real_root = ROOT
    with tempfile.TemporaryDirectory(prefix="ptp-clone-detector-") as folder:
        try:
            ROOT = Path(folder)
            sample = '///|\npub fn sequence(value : Int) -> Int {\n'
            sample += '\n'.join(f'  let part{i} = value + {i}' for i in range(20))
            sample += '\n  part19\n}\n'
            (ROOT / "original.mbt").write_text(sample)
            archive = ROOT / "fixture.zip"
            with zipfile.ZipFile(archive, "w") as z:
                z.writestr("exact.mbt", sample.replace("pub fn", "// irrelevant comment\npub fn"))
                z.writestr("renamed.mbt", sample.replace("sequence", "progression").replace("value", "input").replace("part", "item"))
                z.writestr("negative.mbt", '///|\npub fn other() -> String { "unrelated" }\n')
                z.writestr("generated.mbt", "// Generated by controlled detector self-test\n" + sample)
                z.writestr("fixture_test.mbt", sample)
            audit = ROOT / "audit.json"
            audit.write_text(json.dumps([{"name": "controlled/detector-fixture", "version": "0", "status": "ok", "evidence_file": "fixture.zip", "sha256": digest(archive.read_bytes())}]))
            result = screen(audit, ROOT / "result.json", 80, 8)
            candidates = result["candidate_matches"]
            assert any(m["kind"] == "exact_tokens" and m["external_path"] == "exact.mbt" for m in candidates)
            assert any(m["kind"] == "consistent_identifier_rename_block" and m["external_path"] == "renamed.mbt" for m in candidates)
            assert not any(m["external_path"] == "negative.mbt" for m in candidates)
            assert not any(m["external_path"] in {"generated.mbt", "fixture_test.mbt"} for m in candidates)
            assert result["summary"]["excluded_generated_files"] == 1
            assert result["summary"]["excluded_test_files"] == 1
            inclusive = screen(audit, ROOT / "inclusive.json", 80, 8, include_generated=True, include_tests=True)
            assert any(m["external_path"] == "generated.mbt" for m in inclusive["candidate_matches"])
            assert any(m["external_path"] == "fixture_test.mbt" for m in inclusive["candidate_matches"])
            assert inclusive["summary"]["excluded_generated_files"] == 0
            assert inclusive["summary"]["excluded_test_files"] == 0
            inventory = ROOT / "inventory"
            (inventory / "results").mkdir(parents=True)
            (inventory / "modules.json").write_text(json.dumps([{"name": "controlled/detector-fixture", "version": "0"}, {"name": "controlled/missing", "version": "1"}]))
            (inventory / "results/one.json").write_text(json.dumps({"name": "controlled/detector-fixture", "version": "0", "status": "ok", "cache_file": str(archive), "sha256": digest(archive.read_bytes())}))
            full_audit = inventory / "manifest.json"
            full_audit.write_text(json.dumps({"schema": "mooncakes-full-source-scan/v1", "final": False}))
            result = screen(full_audit, ROOT / "full-result.json", 80, 8)
            assert result["summary"]["packages"] == 1
            assert result["summary"]["unresolved_packages"] == 1
            assert result["summary"]["expected_packages"] == 2
            assert result["unresolved_packages"][0]["name"] == "controlled/missing"
            assert result["source_inventory"]["final"] is False
        finally:
            ROOT = real_root
    print("source-clone detector self-test: passed")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--audit", type=Path, default=DEFAULT_AUDIT)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--minimum-tokens", type=int, default=80)
    parser.add_argument("--minimum-lines", type=int, default=8)
    parser.add_argument("--include-generated", action="store_true")
    parser.add_argument("--include-tests", action="store_true", help="Also compare local production source against third-party test source")
    parser.add_argument("--max-source-bytes", type=int, default=32 * 1024 * 1024)
    parser.add_argument("--progress-every", type=int, default=0)
    parser.add_argument("--shard-count", type=int, default=1)
    parser.add_argument("--shard-index", type=int, default=0)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return
    if args.minimum_tokens < 16 or args.minimum_lines < 2:
        parser.error("minimum tokens >=16 and minimum lines >=2 are required")
    if args.max_source_bytes < 1024:
        parser.error("max-source-bytes >= 1024 is required")
    if args.progress_every < 0:
        parser.error("progress-every must be nonnegative")
    if args.shard_count < 1 or not 0 <= args.shard_index < args.shard_count:
        parser.error("shard-count must be positive and 0 <= shard-index < shard-count")
    screen(args.audit.resolve(), args.output.resolve(), args.minimum_tokens, args.minimum_lines, args.include_generated, args.max_source_bytes, args.include_tests, args.progress_every, args.shard_count, args.shard_index)


if __name__ == "__main__":
    main()
