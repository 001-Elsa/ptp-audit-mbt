#!/usr/bin/env python3
"""Decode the shipped fixture with real TShark, without importing product code.

The expected field values below are an explicit independent fixture contract, not
values produced by MoonBit's decoder. The PCAP is a synthetic Ethernet transport
wrapper around the exact shipped PTP bytes; it is not a hardware capture.
"""

from __future__ import annotations

import argparse
from fractions import Fraction
import hashlib
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import sys


ROOT = Path(__file__).resolve().parent.parent
DEFAULT_TSHARK = Path.home() / ".local/share/ptp-audit-tools/Wireshark.app/Contents/MacOS/tshark"
NAMES = {0: "Sync", 1: "Delay_Req", 8: "Follow_Up", 9: "Delay_Resp", 11: "Announce"}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def flatten(value: dict) -> dict:
    result = {}
    for key, item in value.items():
        if isinstance(item, dict):
            result.update(flatten(item))
        else:
            result[key] = item
    return result


def expected_fields() -> list[dict]:
    """Human-readable values independently specified for complete-audit.json."""
    master = "0x0011223344556677"
    slave = "0x8899aabbccddeeff"
    rows = [
        (0, 44, master, 7, 0, 512, "sdr.origintimestamp", 0, Fraction(-1, 2)),
        (8, 44, master, 7, 2, 0, "fu.preciseorigintimestamp", 1000, Fraction(1, 4)),
        (1, 44, slave, 31, 1, 0, "sdr.origintimestamp", 5000, Fraction(999999, 65536)),
        (9, 54, master, 31, 3, 0, "dr.receivetimestamp", 5250, Fraction(3, 4)),
        (11, 64, master, 7, 5, 0, "an.origintimestamp", 0, Fraction(0)),
        (11, 64, "0x0011223344556678", 7, 5, 0, "an.origintimestamp", 0, Fraction(0)),
    ]
    result = []
    for kind, length, clock, sequence, control, flags, stamp, nanos, correction in rows:
        row = {
            "ptp.v2.messagetype": kind,
            "ptp.v2.majorsdoid": 0,
            "ptp.v2.minorversionptp": 0,
            "ptp.v2.versionptp": 2,
            "ptp.v2.messagelength": length,
            "ptp.v2.domainnumber": 0,
            "ptp.v2.minorsdoid": 0,
            "ptp.v2.flags": flags,
            "ptp.v2.flags.twostep": int(kind == 0),
            "ptp.v2.messagetypespecific": 0,
            "ptp.v2.clockidentity": clock,
            "ptp.v2.sourceportid": 1,
            "ptp.v2.sequenceid": sequence,
            "ptp.v2.controlfield": control,
            "ptp.v2.logmessageinterval": 0,
            f"ptp.v2.{stamp}.seconds": 100,
            f"ptp.v2.{stamp}.nanoseconds": nanos,
            "correction_scaled_ns": correction * 65536,
        }
        if kind == 9:
            row.update({"ptp.v2.dr.requestingsourceportidentity": slave,
                        "ptp.v2.dr.requestingsourceportid": 1})
        if kind == 11:
            row.update({
                "ptp.v2.an.origincurrentutcoffset": 37,
                "ptp.v2.an.reserved2": "00",
                "ptp.v2.an.priority1": 100 if clock == master else 120,
                "ptp.v2.an.grandmasterclockclass": 248,
                "ptp.v2.an.grandmasterclockaccuracy": 34,
                "ptp.v2.an.grandmasterclockvariance": 17185,
                "ptp.v2.an.priority2": 128,
                "ptp.v2.an.grandmasterclockidentity": clock,
                "ptp.v2.an.localstepsremoved": 0,
                "ptp.v2.timesource": 160,
            })
        result.append(row)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tshark", default=os.environ.get("TSHARK") or shutil.which("tshark") or str(DEFAULT_TSHARK))
    parser.add_argument("--fixture", type=Path, default=ROOT / "fixtures/complete-audit.json")
    parser.add_argument("--output", type=Path, default=ROOT / "research/wire-reference")
    args = parser.parse_args()
    executable = Path(args.tshark).resolve()
    if not executable.is_file():
        parser.error("TShark is required; install official Wireshark or supply --tshark /absolute/path/to/tshark")
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=True)
    fixture = json.loads(args.fixture.read_text())
    frames = fixture["frames"]
    expected = expected_fields()
    if len(frames) != len(expected) or [frame["id"] for frame in frames] != list(range(1, 7)):
        raise ValueError("this independent contract requires the six shipped complete-audit frames, IDs 1..6")
    pcap = out / "complete-audit.pcap"
    with pcap.open("wb") as stream:
        stream.write(struct.pack("<IHHIIII", 0xA1B2C3D4, 2, 4, 0, 0, 65535, 1))
        for index, frame in enumerate(frames, 1):
            # IEEE1588 EtherType. Padding is outside the PTP messageLength.
            packet = bytes.fromhex("011b1900000002000000000188f7") + bytes.fromhex(frame["payload_hex"])
            packet = packet.ljust(60, b"\0")
            stream.write(struct.pack("<IIII", 100, index * 1000, len(packet), len(packet)))
            stream.write(packet)
    version = subprocess.run([str(executable), "--version"], check=True, capture_output=True, text=True)
    (out / "tshark-version.txt").write_text(version.stdout + version.stderr)
    command = [str(executable), "-2", "-n", "-r", str(pcap), "-T", "json"]
    decoded = subprocess.run(command, check=True, capture_output=True, text=True)
    (out / "tshark-complete-audit.json").write_text(decoded.stdout)
    (out / "tshark-stderr.txt").write_text(decoded.stderr)
    packets = json.loads(decoded.stdout)
    checks = []
    failures = []
    if len(packets) != len(frames):
        raise AssertionError(f"TShark decoded {len(packets)} packets; expected {len(frames)}")
    for frame, packet, contract in zip(frames, packets, expected):
        fields = flatten(packet["_source"]["layers"].get("ptp", {}))
        if "ptp.v2.correction.ns" in fields and "ptp.v2.correction.subns" in fields:
            # Wireshark emits signed floor(ns) and a positive fractional part.
            fields["correction_scaled_ns"] = (
                Fraction(fields["ptp.v2.correction.ns"]) + Fraction(fields["ptp.v2.correction.subns"])
            ) * 65536
        frame_checks = []
        for field, wanted in contract.items():
            raw = fields.get(field)
            actual = raw
            if isinstance(wanted, int):
                try:
                    actual = int(str(raw), 16 if str(raw).startswith("0x") else 10)
                except (TypeError, ValueError):
                    pass
            passed = actual == wanted
            detail = {"field": field, "expected": str(wanted), "actual": str(actual), "pass": passed}
            frame_checks.append(detail)
            if not passed:
                failures.append({"frame": frame["id"], **detail})
        # The independent dissector must not classify a fixed fixture as malformed.
        malformed = "_ws.malformed" in packet["_source"]["layers"]
        if malformed:
            failures.append({"frame": frame["id"], "field": "_ws.malformed", "pass": False})
        checks.append({"frame": frame["id"], "message": NAMES[contract["ptp.v2.messagetype"]],
                       "payload_sha256": hashlib.sha256(bytes.fromhex(frame["payload_hex"])).hexdigest(),
                       "ptp_length": len(bytes.fromhex(frame["payload_hex"])),
                       "malformed": malformed, "checks": frame_checks})
    manifest = {
        "schema": "ptp-audit/independent-wire-reference/v1",
        "result": "pass" if not failures else "fail",
        "method": "real external TShark two-pass dissection of exact shipped PTP payloads in a synthetic Ethernet PCAP",
        "not_claimed": ["hardware capture provenance", "full IEEE1588 conformance certification", "independent validation of product association, measurements or BMCA algorithm"],
        "fixture": str(args.fixture.resolve().relative_to(ROOT)),
        "fixture_sha256": sha256(args.fixture),
        "tshark_version": version.stdout.splitlines()[0],
        "tshark_binary_sha256": sha256(executable),
        "command": ["tshark", "-2", "-n", "-r", "complete-audit.pcap", "-T", "json"],
        "packet_count": len(packets), "message_types": sorted({row["message"] for row in checks}),
        "field_checks": sum(len(row["checks"]) for row in checks),
        "checks": checks, "failures": failures,
    }
    for path in [pcap, out / "tshark-complete-audit.json", out / "tshark-version.txt"]:
        manifest.setdefault("artifacts", {})[path.name] = {"sha256": sha256(path), "bytes": path.stat().st_size}
    (out / "verification.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Independent TShark wire verification: {manifest['result']}; {len(packets)} packets, {manifest['field_checks']} field checks")
    if failures:
        print(json.dumps(failures, indent=2), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
