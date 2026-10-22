#!/usr/bin/env python3
"""Reproduce the frozen 3,140-module source/README NUL review from cached ZIPs.

This verifier never downloads, imports, compiles, executes, or extracts third-party
source. Its default output is a separate recheck report. The frozen review is an
input, including the human decisions and the exact bytes supporting them; this
script verifies those decisions' recorded byte evidence rather than inventing new
manual classifications. No live index refresh or historical versions are used.
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
import zipfile

HERE = pathlib.Path(__file__).resolve().parent
REVIEW_SHA256 = "d70a4af24380358dc64897ee6516915125e87f1bbaa765b703416c87b85fffc5"
EXPECTED_MODULES = 3140
BLOCK_SIZE = 1024 * 1024
CONTEXT_KEY = re.compile(r'"([0-9] \((?:male|female)\))\x00(th|st|nd|rd)"')


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha_file(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(BLOCK_SIZE), b""):
            digest.update(block)
    return digest.hexdigest()


def identify_bom(content):
    for prefix, encoding in ((b"\xff\xfe\0\0", "utf-32le"),
                             (b"\0\0\xfe\xff", "utf-32be"),
                             (b"\xff\xfe", "utf-16le"),
                             (b"\xfe\xff", "utf-16be"),
                             (b"\xef\xbb\xbf", "utf-8")):
        if content.startswith(prefix):
            return encoding
    return None


def verify_manual_bytes(content, recorded):
    """Check every recorded context and the specific grounds for its category."""
    manual = recorded["manual_review"]
    offsets = [match.start() for match in re.finditer(b"\0", content)]
    require(offsets[:32] == recorded["first_nul_offsets"], "NUL offset list")
    require(content[:64].hex() == recorded["prefix_hex"], "member prefix bytes")
    require(identify_bom(content) == recorded["bom"], "member BOM")
    for encoding, expected in recorded["strict_decoding_checks"].items():
        try:
            decoded = content.decode(encoding, errors="strict")
        except UnicodeError:
            require(expected["valid"] is False, "strict decoding unexpectedly failed: " + encoding)
        else:
            require(expected["valid"] is True, "strict decoding unexpectedly succeeded: " + encoding)
            require(decoded[:160] == expected["preview"], "decoded preview: " + encoding)
    for context in manual["nul_contexts"]:
        offset = context["nul_byte_offset"]
        start = max(0, offset - 64)
        actual = content[start:offset + 64]
        require(content[offset] == 0 and context["context_start"] == start,
                "manual NUL context position")
        require(actual.hex() == context["context_hex"], "manual context exact bytes")
        escaped = actual.decode("utf-8", errors="backslashreplace").encode("unicode_escape").decode("ascii")
        require(escaped == context["context_utf8_escape_view"], "manual context byte escape view")

    category = manual["category"]
    if category == "bom-declared-utf16-already-recognized-by-v4":
        require(recorded["bom"] == "utf-16le" and recorded["inventory_encoding"] == "utf-16",
                "UTF-16 category and registered decoder")
        content.decode("utf-16", errors="strict")
    elif category == "utf8-main-text-with-utf16le-shaped-duplicated-title-tail":
        content.decode("utf-8", errors="strict")
        start = manual["tail_start_byte"]
        tail = content[start:]
        require(start == offsets[0] - 1 and tail.hex() == manual["tail_hex"],
                "exact mixed README tail bytes and offset")
        letters = []
        for index in range(0, len(tail) - 1, 2):
            if not (32 <= tail[index] <= 126 and tail[index + 1] == 0):
                break
            letters.append(chr(tail[index]))
        require("".join(letters) == manual["ascii_nul_pair_prefix"], "README paired ASCII heading")
        require(len(offsets) == len(manual["nul_contexts"]), "every README NUL context recorded")
    elif category == "strict-utf8-source-with-literal-or-comment-nul":
        text = content.decode("utf-8", errors="strict")
        require(recorded["bom"] is None, "literal/comment category unexpectedly has BOM")
        if "full_nul_validation" in manual:
            validation = manual["full_nul_validation"]
            require(validation["exact_pattern"] == CONTEXT_KEY.pattern, "localization context pattern")
            matches = list(CONTEXT_KEY.finditer(text))
            covered = {match.start() + match.group(0).index("\0") for match in matches}
            actual = {match.start() for match in re.finditer("\0", text)}
            require(covered == actual and len(matches) == len(actual) == 700,
                    "all 700 localization NUL separators covered")
            forms = dict(collections.Counter(match.group(1) + "<NUL>" + match.group(2) for match in matches))
            require(forms == validation["distinct_key_forms"] and len(forms) == 20
                    and set(forms.values()) == {35}, "20 key forms in 35 locales")
            require(validation["nul_characters"] == validation["covered_nul_characters"] == 700,
                    "recorded localization coverage")
            require(text.splitlines()[:3] == validation["source_header"], "localization source header")
        else:
            require(offsets == [context["nul_byte_offset"] for context in manual["nul_contexts"]],
                    "every source literal/comment NUL has exact recorded context")
    else:
        raise ValueError("unknown or unfinished manual category: " + str(category))


def scan_archive(result, recorded_archive, cache_override, suffixes):
    pair = (result["name"], result["version"])
    identifier = hashlib.sha256((pair[0] + "\0" + pair[1]).encode()).hexdigest()
    cache = (cache_override / (identifier + ".zip") if cache_override else
             pathlib.Path(result["cache_file"]))
    require(cache.stat().st_size == result["archive_bytes"], "archive byte size: " + str(pair))
    require(sha_file(cache) == result["sha256"] == recorded_archive["archive_sha256"],
            "archive SHA-256: " + str(pair))
    recorded_nuls = {record["path"]: record for record in recorded_archive["nul_members"]}
    require(len(recorded_nuls) == len(recorded_archive["nul_members"]), "duplicate reviewed NUL paths")
    checked_members = checked_bytes = 0
    inventory = hashlib.sha256()
    checked_nuls = []
    with zipfile.ZipFile(cache) as archive:
        members = [item for item in archive.infolist() if not item.is_dir()]
        require(len(members) == len(result["files"]), "member count: " + str(pair))
        for item, expected in zip(members, result["files"]):
            require(item.filename == expected["path"], "member path/order: " + str(pair))
            path = pathlib.PurePosixPath(item.filename)
            if expected["kind"] != "text" or not (path.suffix.lower() in suffixes or
                                                     path.name.lower().startswith("readme")):
                continue
            digest = hashlib.sha256()
            size = nul_count = even_nuls = odd_nuls = 0
            with archive.open(item) as stream:
                for block in iter(lambda: stream.read(BLOCK_SIZE), b""):
                    digest.update(block)
                    nul_count += block.count(0)
                    first, second = block[::2].count(0), block[1::2].count(0)
                    even_nuls += second if size % 2 else first
                    odd_nuls += first if size % 2 else second
                    size += len(block)
            actual_sha = digest.hexdigest()
            require(size == item.file_size == expected["bytes"], "member byte size: " + item.filename)
            require(actual_sha == expected["sha256"], "member SHA-256: " + item.filename)
            inventory.update(json.dumps([item.filename, size, actual_sha], ensure_ascii=False,
                                        separators=(",", ":")).encode() + b"\n")
            checked_members += 1
            checked_bytes += size
            if nul_count:
                require(item.filename in recorded_nuls, "new unreviewed NUL member: " + item.filename)
                recorded = recorded_nuls[item.filename]
                require(size == recorded["bytes"] and actual_sha == recorded["sha256"]
                        and expected["encoding"] == recorded["inventory_encoding"], "reviewed member identity")
                require(nul_count == recorded["nul_bytes"] and even_nuls == recorded["nul_at_even_offsets"]
                        and odd_nuls == recorded["nul_at_odd_offsets"], "reviewed NUL counts")
                content = archive.read(item)
                require(hashlib.sha256(content).hexdigest() == actual_sha, "manual reread SHA-256")
                verify_manual_bytes(content, recorded)
                checked_nuls.append(recorded)
            else:
                require(item.filename not in recorded_nuls, "recorded NUL disappeared: " + item.filename)
    require({record["path"] for record in checked_nuls} == set(recorded_nuls), "reviewed NUL path coverage")
    require(checked_members == recorded_archive["selected_members"]
            and checked_bytes == recorded_archive["selected_bytes"], "per-archive source scope counts")
    require(inventory.hexdigest() == recorded_archive["checked_member_inventory_sha256"],
            "per-archive selected member inventory digest")
    require(sha_file(cache) == result["sha256"], "archive changed during reads: " + str(pair))
    return {**recorded_archive, "archive_cache_file": str(cache),
            "selected_members": checked_members, "selected_bytes": checked_bytes,
            "nul_members": checked_nuls, "checked_member_inventory_sha256": inventory.hexdigest()}


def run(args):
    directory = args.directory.resolve()
    review_path = directory / "text-source-nul-review.json"
    output_path = args.output.resolve() if args.output else directory / "text-source-nul-review-recheck.json"
    require(output_path != review_path.resolve(), "refusing to overwrite the frozen NUL review")
    frozen = {}

    def read_bound(path, expected_sha=None):
        raw = path.read_bytes()
        actual_sha = hashlib.sha256(raw).hexdigest()
        require(expected_sha is None or expected_sha == actual_sha, "bound input SHA-256: " + str(path))
        frozen[path] = actual_sha
        return json.loads(raw)

    review = read_bound(review_path, REVIEW_SHA256)
    require(review["result"] == "pass" and review["completed_results"] == review["index_modules"] == EXPECTED_MODULES
            and review["not_yet_v4_ok"] == [] and review["manual_review"]["pending_members"] == 0,
            "the frozen review is incomplete")
    manifest_path = directory / "manifest.json"
    manifest = read_bound(manifest_path, review["main_manifest_sha256"])
    require(manifest["final"] is True and manifest["processed_modules"] == manifest["expected_modules"] == EXPECTED_MODULES
            and manifest["statuses"] == {"ok": EXPECTED_MODULES, "limited": 0, "unavailable": 0, "error": 0}
            and manifest["unresolved"] == [], "main scan is not final and complete")
    modules = read_bound(directory / "modules.json", review["modules_json_sha256"])
    pairs = [(module["name"], module["version"]) for module in modules]
    require(len(pairs) == len(set(pairs)) == EXPECTED_MODULES, "index pair scope")
    require([(binding["name"], binding["version"]) for binding in manifest["result_bindings"]] == pairs,
            "main result bindings do not match captured index")
    index = read_bound(directory / "index.json")
    require(index == manifest["index"], "main index metadata")
    require(read_bound(directory / index["raw_body_file"], index["raw_sha256"]) == modules,
            "raw/pretty index mismatch")
    require(manifest["modules_json_sha256"] == index["modules_json_sha256"] == review["modules_json_sha256"],
            "pretty index binding")
    require(manifest["scanner_version"] == review["main_scanner_version"] == 4
            and manifest["scanner_sha256"] == review["main_scanner_sha256"], "main scanner binding")
    scanner_path = directory.parents[1] / "scripts/audit_all_mooncakes_sources.py"
    require(sha_file(scanner_path) == manifest["scanner_sha256"], "main scanner SHA-256")
    frozen[scanner_path] = manifest["scanner_sha256"]
    config_path = directory / "encoding-overrides.json"
    require(sha_file(config_path) == manifest["encoding_overrides_sha256"] == review["encoding_overrides_sha256"],
            "encoding configuration SHA-256")
    frozen[config_path] = manifest["encoding_overrides_sha256"]
    self_path = pathlib.Path(__file__).resolve()
    frozen[self_path] = sha_file(self_path)
    reviewed = {(item["name"], item["version"]): item for item in review["archives"]}
    require(len(reviewed) == len(review["archives"]) == EXPECTED_MODULES and set(reviewed) == set(pairs),
            "review archive pair coverage")
    entries = []
    for binding in manifest["result_bindings"]:
        pair = (binding["name"], binding["version"])
        expected_file = "results/" + hashlib.sha256((pair[0] + "\0" + pair[1]).encode()).hexdigest() + ".json"
        require(binding["file"] == expected_file, "result binding path")
        result = read_bound(directory / binding["file"], binding["sha256"])
        require((result["name"], result["version"]) == pair and result["status"] == "ok"
                and result["limitations"] == [] and result["scanner_version"] == 4
                and result["scanner_sha256"] == manifest["scanner_sha256"], "result identity/status")
        require(reviewed[pair]["result_file"] == binding["file"]
                and reviewed[pair]["result_sha256"] == binding["sha256"], "review result binding")
        entries.append((result, reviewed[pair]))
    suffixes = set(review["suffixes"])
    cache_override = args.cache.resolve() if args.cache else None
    archives = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = [pool.submit(scan_archive, result, recorded, cache_override, suffixes)
                   for result, recorded in entries]
        for count, future in enumerate(concurrent.futures.as_completed(futures), 1):
            archives.append(future.result())
            if count % 500 == 0 or count == len(entries):
                print(json.dumps({"checked_results": count, "expected_results": len(entries)}), flush=True)
    archives.sort(key=lambda item: (item["name"], item["version"]))
    for path, expected_sha in frozen.items():
        require(sha_file(path) == expected_sha, "bound input changed during recheck: " + str(path))
    require(output_path not in {path.resolve() for path in frozen},
            "refusing to overwrite a bound input file")
    categories = dict(collections.Counter(record["manual_review"]["category"]
                                         for archive in archives for record in archive["nul_members"]))
    require(categories == review["manual_review"]["nul_member_categories"], "manual category totals")
    for field, actual in (("selected_members", sum(item["selected_members"] for item in archives)),
                          ("selected_bytes", sum(item["selected_bytes"] for item in archives)),
                          ("nul_members", sum(len(item["nul_members"]) for item in archives))):
        require(actual == review[field], "final source review count: " + field)
    output = {**review, "archives": archives,
              "recheck": {"result": "pass", "checked_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
                          "scanner_sha256": frozen[self_path], "source_review_sha256": REVIEW_SHA256,
                          "manual_byte_evidence_verified": review["nul_members"],
                          "method": "Rehash every captured archive before/after reads; reproduce exact selected-member inventory; verify all preserved manual byte contexts and category-specific grounds."}}
    temporary = output_path.with_suffix(output_path.suffix + ".tmp")
    temporary.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n")
    temporary.replace(output_path)
    return {"result": "pass", "output": str(output_path), "output_sha256": sha_file(output_path),
            "script_sha256": frozen[self_path], "source_review_sha256": REVIEW_SHA256,
            "completed_results": EXPECTED_MODULES, "selected_members": review["selected_members"],
            "selected_bytes": review["selected_bytes"], "nul_members": review["nul_members"],
            "manual_byte_evidence_verified": review["nul_members"], "categories": categories}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=pathlib.Path, default=HERE)
    parser.add_argument("--cache", type=pathlib.Path, help="optional mirror of the already captured ZIP cache")
    parser.add_argument("--output", type=pathlib.Path, help="new report path; frozen input cannot be overwritten")
    parser.add_argument("--workers", type=int, default=8)
    args = parser.parse_args()
    try:
        require(1 <= args.workers <= 24, "workers must be between 1 and 24")
        result = run(args)
    except (ValueError, KeyError, OSError, zipfile.BadZipFile, UnicodeError, RuntimeError) as error:
        print(json.dumps({"result": "fail", "error": str(error)}), file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False), flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
