#!/usr/bin/env python3
"""Render the single-page project proposal from its checked-in Markdown source.

Requires reportlab and pypdf. No login, network access or publication is used.
Use --font to supply a CJK TrueType font outside macOS. Fonts are embedded;
the font file itself is never copied into the product or submission archive.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph
from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "output/pdf/ptp-audit-项目申报书.pdf"


def plain_text(text: str) -> str:
    return re.sub(r"\[([^\]]+)\]\(https?://[^)]+\)", r"\1", text).replace("`", "")


def paragraph_markup(text: str) -> str:
    """Preserve the proposal's public Markdown links as clickable PDF text."""
    parts = []
    start = 0
    for match in re.finditer(r"\[([^\]]+)\]\((https?://[^)]+)\)", text):
        parts.append(escape(text[start:match.start()].replace("`", "")))
        parts.append(f'<link href="{escape(match[2], {chr(34): "&quot;"})}">{escape(match[1])}</link>')
        start = match.end()
    parts.append(escape(text[start:].replace("`", "")))
    return "".join(parts)


def proposal(path: Path) -> tuple[str, str, list[tuple[str, list[str]]]]:
    lines = path.read_text().splitlines()
    title = lines[0].removeprefix("# ")
    subtitle = next(line for line in lines[1:] if line.strip())
    sections = []
    for line in lines[2:]:
        if line.startswith("## "):
            sections.append((line[3:], []))
        elif line.strip() and sections:
            sections[-1][1].append(line.strip())
    if len(sections) != 6:
        raise ValueError("Proposal must have exactly six complete sections")
    return title, subtitle, sections


def font_path(explicit: str | None) -> Path:
    candidates = [explicit, os.environ.get("PTP_PDF_FONT"),
                  "/System/Library/Fonts/Supplemental/Songti.ttc",
                  "/Library/Fonts/Arial Unicode.ttf"]
    for value in candidates:
        if value and Path(value).is_file():
            return Path(value)
    raise RuntimeError("Supply --font with a CJK TrueType font; see docs/submission-ready.md")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=ROOT / "PROJECT_APPLICATION.md")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--font")
    args = parser.parse_args()
    title, subtitle, sections = proposal(args.source)
    selected_font = font_path(args.font)
    songti = selected_font.name == "Songti.ttc"
    pdfmetrics.registerFont(TTFont("ProposalCJK", str(selected_font), subfontIndex=6 if songti else 0))
    pdfmetrics.registerFont(TTFont("ProposalHeading", str(selected_font), subfontIndex=1 if songti else 0))
    width, height = A4
    left, right = 43, width - 43
    content_width = right - left
    body = ParagraphStyle("Body", fontName="ProposalCJK", fontSize=10.7,
                          leading=16.3, textColor=colors.HexColor("#243449"),
                          alignment=TA_LEFT, wordWrap="CJK", spaceAfter=4)
    heading = ParagraphStyle("Section", parent=body, fontName="ProposalHeading", fontSize=11.4, leading=16.4,
                             textColor=colors.HexColor("#135E70"))
    title_style = ParagraphStyle("Title", parent=body, fontName="ProposalHeading", fontSize=19.5, leading=27,
                                 textColor=colors.HexColor("#142D49"))

    args.output.parent.mkdir(parents=True, exist_ok=True)
    c = canvas.Canvas(str(args.output), pagesize=A4, pageCompression=1,
                      invariant=1)
    c.setTitle(plain_text(title))
    c.setSubject("2026 MoonBit 黑客松十月赛项目申报书")
    c.setCreator("ptp-audit proposal renderer / ReportLab")
    c.setFillColor(colors.HexColor("#135E70"))
    c.rect(left, height - 47, 35, 3, fill=1, stroke=0)
    y = height - 65
    p = Paragraph(paragraph_markup(title), title_style)
    _, h = p.wrap(content_width, height)
    p.drawOn(c, left, y - h)
    y -= h + 8
    c.setFont("ProposalCJK", 9.4)
    c.setFillColor(colors.HexColor("#52667C"))
    c.drawString(left, y, subtitle)
    y -= 18
    c.setStrokeColor(colors.HexColor("#D5DFE7"))
    c.line(left, y, right, y)
    y -= 14
    boxes = []
    for label, paragraphs in sections:
        p = Paragraph(escape(label), heading)
        _, h = p.wrap(content_width, height)
        p.drawOn(c, left, y - h)
        y -= h + 3
        for text in paragraphs:
            is_bullet = text.startswith("- ")
            text = text.removeprefix("- ")
            prefix = "- " if is_bullet else ""
            p = Paragraph(paragraph_markup(prefix + text), body)
            _, h = p.wrap(content_width - (8 if is_bullet else 0), height)
            p.drawOn(c, left + (8 if is_bullet else 0), y - h)
            boxes.append({"section": label, "top": y, "bottom": y - h})
            y -= h + 3
        y -= 6
    if y < 43:
        raise RuntimeError(f"Proposal exceeds one-page safe area: bottom={y:.1f}pt")
    c.setStrokeColor(colors.HexColor("#D5DFE7"))
    c.line(left, 35, right, 35)
    c.setFillColor(colors.HexColor("#52667C"))
    c.setFont("ProposalCJK", 8)
    c.drawString(left, 22, "项目说明 · 0.3.0 · 核心实现、验证结果及边界见随附源码与验收记录")
    c.setFont("Helvetica", 8)
    c.drawRightString(right, 22, "1 / 1")
    c.save()

    reader = PdfReader(args.output)
    text = "\n".join(page.extract_text() for page in reader.pages)
    if len(reader.pages) != 1:
        raise RuntimeError("Proposal must contain exactly one page")
    for section, _ in sections:
        if section not in text:
            raise RuntimeError("PDF lost proposal section: " + section)
    if any(token in text for token in ("待填写", "TODO", "PLACEHOLDER")):
        raise RuntimeError("Proposal contains unfinished placeholders")
    fonts = reader.pages[0]["/Resources"]["/Font"].get_object()
    embedded = []
    for font in fonts.values():
        font = font.get_object()
        descriptor = font.get("/FontDescriptor")
        if descriptor:
            descriptor = descriptor.get_object()
            if any(key in descriptor for key in ("/FontFile", "/FontFile2", "/FontFile3")):
                embedded.append(str(font.get("/BaseFont")))
    if not embedded:
        raise RuntimeError("No embedded CJK font found")
    info = {"schema": "ptp-proposal-pdf/v1", "pages": len(reader.pages),
            "source": args.source.relative_to(ROOT).as_posix(),
            "source_sha256": hashlib.sha256(args.source.read_bytes()).hexdigest(),
            "pdf_sha256": hashlib.sha256(args.output.read_bytes()).hexdigest(),
            "font_source": str(selected_font), "embedded_fonts": embedded,
            "bottom_content_pt": y, "section_boxes": boxes,
            "personal_fields": "omitted at user request; entered separately in official form",
            "visual_review": "Render and inspect the final PDF before delivery"}
    args.output.with_suffix(".verification.json").write_text(
        json.dumps(info, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({"pdf": str(args.output), "pages": 1,
                      "bottom_content_pt": round(y, 1), "embedded_fonts": embedded}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
