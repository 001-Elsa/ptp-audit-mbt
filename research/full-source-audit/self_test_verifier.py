#!/usr/bin/env python3
"""Exercise the independent verifier with a tiny, locally generated ZIP."""
import argparse
import contextlib
import copy
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import zipfile

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("full_source_verifier", HERE / "verify_manifest.py")
verifier = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verifier)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def main():
    checks = []
    with tempfile.TemporaryDirectory() as temp:
        directory = Path(temp)
        cache = directory / "cache"
        cache.mkdir()
        (directory / "results").mkdir()
        modules = [{"name": "test/manifest", "version": "1.0.0"}]
        ident = verifier.ident("test/manifest", "1.0.0")
        archive = cache / (ident + ".zip")
        with zipfile.ZipFile(archive, "w") as zipped:
            zipped.writestr("source.mbt", b"fn main { () }\n")
            zipped.writestr("asset.bin", b"\0\xff\x01")
        files = []
        with zipfile.ZipFile(archive) as zipped:
            for info in zipped.infolist():
                data = zipped.read(info)
                files.append({"path": info.filename, "bytes": len(data),
                              "sha256": hashlib.sha256(data).hexdigest(),
                              "kind": "text" if info.filename.endswith(".mbt") else "binary",
                              "encoding": "utf-8-sig" if info.filename.endswith(".mbt") else None,
                              "encoding_basis": None, "classification": None,
                              "decode_replacement": False})
        raw = json.dumps(modules).encode()
        (directory / "modules-response.raw.json").write_bytes(raw)
        write_json(directory / "modules.json", modules)
        write_json(directory / "encoding-overrides.json", {})
        index = {"raw_body_file": "modules-response.raw.json", "raw_sha256": hashlib.sha256(raw).hexdigest(),
                 "modules_json_sha256": verifier.sha_file(directory / "modules.json"),
                 "count": 1, "unique_name_versions": 1}
        write_json(directory / "index.json", index)
        result = {"name": "test/manifest", "version": "1.0.0", "status": "ok", "limitations": [],
                  "files": files, "hits": [], "scanner_version": 4,
                  "scanner_sha256": verifier.sha_file(verifier.ROOT / "scripts/audit_all_mooncakes_sources.py"),
                  "archive_bytes": archive.stat().st_size, "sha256": verifier.sha_file(archive),
                  "expanded_bytes": sum(f["bytes"] for f in files), "text_bytes": files[0]["bytes"],
                  "text_files": 1, "binary_files": 1}
        result_path = directory / "results" / (ident + ".json")
        write_json(result_path, result)
        manifest = {"final": True, "index": index, "modules_json_sha256": index["modules_json_sha256"],
                    "expected_modules": 1, "expected_unique_name_versions": 1, "processed_modules": 1,
                    "statuses": {"ok": 1, "limited": 0, "unavailable": 0, "error": 0}, "unresolved": [],
                    "scanner_version": 4, "scanner_sha256": result["scanner_sha256"],
                    "encoding_overrides_sha256": verifier.sha_file(directory / "encoding-overrides.json"),
                    "result_bindings": [{"name": "test/manifest", "version": "1.0.0",
                                         "file": "results/" + result_path.name, "sha256": verifier.sha_file(result_path)}],
                    "cache": str(cache), "text_files": 1, "text_bytes": result["text_bytes"],
                    "archive_bytes": result["archive_bytes"], "hit_modules": []}
        manifest_path = directory / "manifest.json"
        write_json(manifest_path, manifest)
        args = argparse.Namespace(directory=directory, cache=cache, workers=2, archives_only=False)
        with contextlib.redirect_stdout(io.StringIO()):
            output = verifier.verify(args)
        assert output["verified_archives"] == 1 and output["member_hashes_verified"] == 2
        checks.append({"case": "valid text and binary members", "result": "pass"})
        mutations = [
            ("not final", lambda item: item.update(final=False)),
            ("error status", lambda item: item.update(statuses={"ok": 0, "limited": 0, "unavailable": 0, "error": 1})),
            ("stale result binding", lambda item: item["result_bindings"][0].update(sha256="0" * 64)),
            ("wrong scanner identity", lambda item: item.update(scanner_sha256="0" * 64)),
            ("wrong derived hit inventory", lambda item: item["hit_modules"].append({"name": "fake", "version": "0"})),
        ]
        for label, mutation in mutations:
            changed = copy.deepcopy(manifest)
            mutation(changed)
            write_json(manifest_path, changed)
            try:
                verifier.verify(args)
            except ValueError:
                checks.append({"case": label, "result": "correctly rejected"})
            else:
                raise AssertionError(label + " accepted")
        changed_overrides = {"overrides": {ident + ".zip": {"source.mbt": {"encoding": "latin1", "basis": "deliberately changed test policy"}}}}
        write_json(directory / "encoding-overrides.json", changed_overrides)
        changed_manifest = copy.deepcopy(manifest)
        changed_manifest["encoding_overrides_sha256"] = verifier.sha_file(directory / "encoding-overrides.json")
        write_json(manifest_path, changed_manifest)
        try:
            verifier.verify(args)
        except ValueError:
            checks.append({"case": "changed override with stale per-file encoding record", "result": "correctly rejected"})
        else:
            raise AssertionError("stale per-file encoding record accepted")
        write_json(directory / "encoding-overrides.json", {})
        changed_result = copy.deepcopy(result)
        changed_result["files"][0]["sha256"] = "0" * 64
        write_json(result_path, changed_result)
        changed_manifest = copy.deepcopy(manifest)
        changed_manifest["result_bindings"][0]["sha256"] = verifier.sha_file(result_path)
        write_json(manifest_path, changed_manifest)
        try:
            with contextlib.redirect_stdout(io.StringIO()):
                verifier.verify(args)
        except ValueError:
            checks.append({"case": "wrong member SHA despite rebound result", "result": "correctly rejected"})
        else:
            raise AssertionError("wrong member SHA accepted")
    output = {"result": "pass", "checks": checks,
              "verifier_sha256": verifier.sha_file(HERE / "verify_manifest.py"),
              "self_test_sha256": verifier.sha_file(Path(__file__))}
    write_json(HERE / "verifier-self-test.json", output)
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
