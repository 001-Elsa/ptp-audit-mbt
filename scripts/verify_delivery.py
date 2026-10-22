#!/usr/bin/env python3
"""Bind submission docs to the tested working tree and check their public claims.

This checks concrete version/API/schema/count/link claims and freezes document
hashes. It does not certify every sentence, IEEE conformance, authorship, or the
unread authenticated contest charter. It uses only Python's standard library;
--pdf additionally requires pypdf and the separately generated one-page PDF.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import re
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[1]
CURRENT = ROOT / "research/delivery/current.json"
DOCS = [ROOT / "README.mbt.md", ROOT / "PROJECT_APPLICATION.md", ROOT / "SUBMISSION.md",
        ROOT / "THIRD_PARTY.md", ROOT / "CHANGELOG.md", *sorted((ROOT / "docs").glob("*.md"))]
DELIVERY_CONFIG = [ROOT / ".github/workflows/test.yml", ROOT / ".moonignore", ROOT / ".gitignore",
                   ROOT / "research/contest-2026-10-22/website-source.json"]


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def snapshot(paths) -> dict[str, str]:
    return {path.relative_to(ROOT).as_posix(): sha(path) for path in sorted(set(paths))}


def verify_pdf() -> dict:
    from pypdf import PdfReader
    pdf = ROOT / "output/pdf/ptp-audit-项目申报书.pdf"
    info_path = pdf.with_suffix(".verification.json")
    info = json.loads(info_path.read_text())
    assert info["source_sha256"] == sha(ROOT / "PROJECT_APPLICATION.md"), "PDF text source is stale"
    assert info["pdf_sha256"] == sha(pdf), "PDF bytes differ from generation evidence"
    reader = PdfReader(pdf)
    assert len(reader.pages) == 1, "Proposal is not exactly one page"
    assert abs(float(reader.pages[0].mediabox.width) - 595.2756) < 0.1 and abs(float(reader.pages[0].mediabox.height) - 841.8898) < 0.1, "Expected A4 proposal"
    text = "\n".join(page.extract_text() for page in reader.pages)
    assert all(x in text for x in ("项目简介与实际需求", "本期新增贡献", "开源合规", "6,004", "455", "935")), "Missing PDF claims"
    assert not any(x in text for x in ("待填写", "TODO", "PLACEHOLDER")), "Unfinished PDF placeholders"
    fonts = reader.pages[0]["/Resources"]["/Font"].get_object()
    assert any(font.get_object().get("/FontDescriptor") for font in fonts.values()), "No embedded CJK font"
    return {"path": pdf.relative_to(ROOT).as_posix(), "pages": 1,
            "sha256": sha(pdf), "source_sha256": info["source_sha256"]}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="Refresh the current delivery source/document hash snapshot")
    parser.add_argument("--pdf", action="store_true", help="Also validate the separately generated proposal PDF")
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location("package_local", ROOT / "scripts/package_local.py")
    package = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(package)
    validation = package.verify_validation(ROOT, "0.3.0")
    manifest = json.loads((ROOT / validation["manifest"]).read_text())
    operational = json.loads((ROOT / "research/commissioning/manifest.json").read_text())
    fixtures = json.loads((ROOT / "fixtures/manifest.json").read_text())["cases"]
    new_cases = json.loads((ROOT / "fixtures/commissioning/manifest.json").read_text())["cases"]
    rule_inventory = json.loads((ROOT / "research/normative-completion/rule-inventory.json").read_text())
    version = re.search(r'^version\s*=\s*"([^"]+)"', (ROOT / "moon.mod").read_text(), re.M).group(1)
    assert version == manifest["version"] == "0.3.0", "Version and validation differ"
    assert (ROOT / "README.md").read_bytes() == (ROOT / "README.mbt.md").read_bytes(), "README copies diverged"
    assert not (ROOT / "research/wireshark/ptpv2.pcap").exists(), "Withdrawn external capture returned"
    assert "Apache License" in (ROOT / "LICENSE").read_text(), "Missing Apache license"
    for path in (ROOT / ".gitignore", ROOT / ".moonignore"):
        assert "research/wireshark/ptpv2.pcap" in path.read_text(), "Missing withdrawn-sample exclusion"
    api = (ROOT / "pkg.generated.mbti").read_text()
    for name in ("audit_json", "commission_json"):
        assert f"pub fn {name}(" in api, "Documented API missing: " + name
    cli = (ROOT / "bin/ptp-audit.mjs").read_text()
    assert "['check','commission']" in cli, "Documented commands differ from CLI"
    assert f"ptp-audit {version}" in cli, "CLI version differs"
    schemas = {"audit/audit.mbt": ["ptp-audit/v1", "ptp-audit-report/v2"],
               "commissioning/commissioning.mbt": ["ptp-commission/v1", "ptp-commission-report/v1"]}
    readme = (ROOT / "README.mbt.md").read_text()
    for path, values in schemas.items():
        source = (ROOT / path).read_text()
        assert all(value in source and value in readme for value in values), "Schema docs and source differ"
    tests = sorted(manifest["backend_tests"], key=lambda test: test["target"])
    assert {test["total"] for test in tests} == {455}, "Update proposal/document test figures after changes"
    assert manifest["product_effective_moonbit_lines"] == 6004, "Update proposal/document LOC after changes"
    assert len(fixtures) == 116 and len(new_cases) == 53, "Update fixture figures after changes"
    assert len(rule_inventory["rules"]) == 95, "Update documented rule inventory after changes"
    report_log = (ROOT / "research/validation-0.3.0/report-evidence.log").read_text()
    operation_log = (ROOT / "research/validation-0.3.0/operational-evidence.log").read_text()
    assert "1012 checks passed" in report_log, "Update report evidence figure"
    assert "935 checks; 53 fixtures" in operation_log, "Update operational evidence figures"
    for path in (ROOT / "PROJECT_APPLICATION.md", ROOT / "docs/validation.md", ROOT / "docs/submission-ready.md"):
        text = path.read_text()
        assert "6,004" in text and "455" in text, "Current evidence not reflected in " + path.name
    for path in DOCS:
        for target in re.findall(r'(?<!!)\[[^\]]*\]\(([^)]+)\)', path.read_text()):
            target = target.strip().split(" ", 1)[0].strip("<>")
            if target.startswith(("http:", "https:", "mailto:", "#", "codex:")):
                continue
            candidate = path.parent / unquote(target.split("#")[0])
            assert candidate.exists(), f"Broken local documentation link: {path.name} -> {target}"
    workflow = (ROOT / ".github/workflows/test.yml").read_text()
    assert all(command in workflow for command in ("scripts/validate_local.py", "build --target all", "scripts/verify_delivery.py", "scripts/package_local.py")), "CI and local delivery gates differ"
    sources = snapshot([ROOT / path for path in manifest["source_sha256"]])
    docs = snapshot(DOCS + DELIVERY_CONFIG)
    summary = {"schema": "ptp-delivery-doc-bindings/v1", "version": version,
               "scope": "Current tested release sources and documents; remote publication verified separately; personal registration excluded",
               "source_sha256": sources, "document_sha256": docs,
               "backend_tests": tests, "effective_moonbit_lines": 6004,
               "cli_fixtures": len(fixtures) + len(new_cases), "cli_boundaries": 7,
               "report_checks": 1012, "operational_checks": 935,
               "rule_ids": len(rule_inventory["rules"]),
               "withdrawn_capture_absent": True,
               "website_deadline": "2026-10-31", "feishu_full_charter_readable": False}
    if args.write:
        CURRENT.parent.mkdir(parents=True, exist_ok=True)
        CURRENT.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n")
    else:
        saved = json.loads(CURRENT.read_text())
        assert saved == summary, "Delivery docs/sources changed: review them and run verify_delivery.py --write"
    pdf = verify_pdf() if args.pdf else None
    print(json.dumps({"result": "pass", "source_files": len(sources), "document_files": len(docs),
                      "cli_fixtures": summary["cli_fixtures"], "pdf": pdf}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
