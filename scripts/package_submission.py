#!/usr/bin/env python3
"""Bundle the one-page PDF and verified source ZIP without publishing anything."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import zipfile


ROOT = Path(__file__).resolve().parents[1]


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    # This validates tested-source and documentation bindings as well as PDF.
    subprocess.run([sys.executable, "scripts/verify_delivery.py", "--pdf"], cwd=ROOT, check=True)
    output = ROOT / "output/submission"
    contents = output / "ptp-audit-0.3.0-参赛材料"
    output.mkdir(parents=True, exist_ok=True)
    if contents.exists():
        shutil.rmtree(contents)
    contents.mkdir()
    package_dir = ROOT / "_build/publish"
    report_path = package_dir / "package-audit-0.3.0.json"
    report = json.loads(report_path.read_text())
    source = package_dir / report["archive"]
    assert report["result"] == "pass" and report["archive_sha256"] == sha(source), "Source archive is not verified"
    with zipfile.ZipFile(source) as archive:
        assert archive.testzip() is None, "Source ZIP CRC error"
        for name, digest in report["entry_sha256"].items():
            assert hashlib.sha256(archive.read(name)).hexdigest() == digest, "Source archive content changed: " + name
            assert sha(ROOT / name) == digest, "Workspace changed since source packaging: " + name
        assert "research/wireshark/ptpv2.pcap" not in archive.namelist(), "Withdrawn external data leaked"
        assert ".git/HEAD" not in archive.namelist(), "Git history is not a submission artifact"
    files = {
        "项目申报书.pdf": ROOT / "output/pdf/ptp-audit-项目申报书.pdf",
        "PROJECT_APPLICATION.md": ROOT / "PROJECT_APPLICATION.md",
        "提交说明.md": ROOT / "SUBMISSION.md",
        source.name: source,
        report_path.name: report_path,
    }
    for name, path in files.items():
        shutil.copy2(path, contents / name)
    sums = {name: sha(contents / name) for name in files}
    (contents / "SHA256SUMS.txt").write_text("".join(f"{digest}  {name}\n" for name, digest in sorted(sums.items())))
    archive_path = output / "ptp-audit-0.3.0-参赛材料.zip"
    with zipfile.ZipFile(archive_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(contents.iterdir()):
            archive.write(path, contents.name + "/" + path.name)
    with zipfile.ZipFile(archive_path) as archive:
        assert archive.testzip() is None
        for name, digest in sums.items():
            assert hashlib.sha256(archive.read(contents.name + "/" + name)).hexdigest() == digest
    audit = {"result": "pass", "archive": archive_path.name,
             "archive_sha256": sha(archive_path), "archive_bytes": archive_path.stat().st_size,
             "files": sums, "source_package_verified": True, "proposal_pages": 1,
             "scope": "Local materials only; no login, push, registry publication or official submission"}
    (output / "submission-audit.json").write_text(json.dumps(audit, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(audit, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
