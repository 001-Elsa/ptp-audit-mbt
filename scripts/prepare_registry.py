#!/usr/bin/env python3
"""Stage a compact registry module from the verified full source archive.

The full source archive and Git repositories retain all research evidence.
Registry consumers receive identical product/test/doc bytes without research/.
This command does not log in, upload, or change the source working tree.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import shutil
import stat
import zipfile

from package_local import safe_name


ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / "_build/registry-stage"


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    report = json.loads((ROOT / "_build/publish/package-audit-0.3.0.json").read_text())
    archive = ROOT / "_build/publish" / report["archive"]
    assert report["result"] == "pass" and sha(archive.read_bytes()) == report["archive_sha256"], "Rebuild and verify the full source archive first"
    if STAGE.exists():
        shutil.rmtree(STAGE)
    STAGE.mkdir(parents=True)
    entries = {}
    omitted = []
    with zipfile.ZipFile(archive) as source:
        assert source.testzip() is None, "Source archive CRC failure"
        assert set(source.namelist()) == set(report["entry_sha256"]), "Source archive inventory changed"
        for info in source.infolist():
            name = info.filename
            safe_name(name)
            data = source.read(name)
            assert sha(data) == report["entry_sha256"][name] == sha((ROOT / name).read_bytes()), "Source or workspace changed: " + name
            if name.startswith("research/"):
                omitted.append(name)
                continue
            target = STAGE / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            mode = info.external_attr >> 16
            if mode & stat.S_IXUSR:
                target.chmod(0o755)
            entries[name] = sha(data)
    assert all((STAGE / name).is_file() for name in ("moon.mod", "moon.pkg", "facade.mbt", "README.md", "LICENSE", "THIRD_PARTY.md", "scripts/moon-local"))
    record = {"schema": "ptp-registry-staging/v1", "module": "001-Elsa/ptp-audit", "version": "0.3.0",
              "full_source_archive_sha256": report["archive_sha256"], "stage": str(STAGE),
              "entry_sha256": entries, "omitted_research_files": len(omitted),
              "omission_policy": "research/ only; complete evidence remains in both Git repositories and the full submission source ZIP",
              "all_included_bytes_match_verified_source": True}
    (ROOT / "_build/publish/registry-staging-0.3.0.json").write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({"result": "pass", "stage": str(STAGE), "files": len(entries), "omitted_research_files": len(omitted)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
