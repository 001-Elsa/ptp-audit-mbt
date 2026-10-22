#!/usr/bin/env python3
"""Verify the shipping CLI's concrete evidence, not only its aggregate status.

Expected wire fields and arithmetic operands are independently read from the
fixture with Python struct/Fraction. This does not authenticate captured input
or certify IEEE conformance; it checks that report v2 explains its own verdict.
"""

from __future__ import annotations

import argparse
import copy
from fractions import Fraction
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def timestamp(value: dict) -> int:
    return int(value["seconds"]) * 1_000_000_000 + value["nanos"]


def wire_time(payload: bytes) -> int:
    return int.from_bytes(payload[34:40], "big") * 1_000_000_000 + int.from_bytes(payload[40:44], "big")


def run_cli(case: dict) -> tuple[dict, int]:
    with tempfile.TemporaryDirectory(prefix="ptp-report-evidence-") as temporary:
        path = Path(temporary) / "case.json"
        path.write_text(json.dumps(case, indent=2) + "\n")
        result = subprocess.run(
            [str(ROOT / "bin/ptp-audit.mjs"), "check", str(path), "--json"],
            cwd=ROOT, capture_output=True, text=True,
        )
        try:
            return json.loads(result.stdout), result.returncode
        except json.JSONDecodeError as error:
            raise AssertionError(f"CLI did not produce report JSON: {result.stderr}") from error


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "research/report-evidence")
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    fixture_path = ROOT / "fixtures/complete-audit.json"
    case = json.loads(fixture_path.read_text())
    checks = []

    def check(name: str, actual, expected) -> None:
        passed = actual == expected
        checks.append({"check": name, "actual": actual, "expected": expected, "pass": passed})
        if not passed:
            raise AssertionError(f"{name}: expected {expected!r}, actual {actual!r}")

    report, code = run_cli(case)
    (output / "complete-report.json").write_text(json.dumps(report, indent=2) + "\n")
    check("report schema distinguishes v2 assumptions object", report["schema"], "ptp-audit-report/v2")
    check("complete CLI status", report["status"], "Pass")
    check("complete CLI exit", code, 0)
    check("actual assumptions preserved", report["assumptions"], case["assumptions"])
    frames = {frame["id"]: frame for frame in case["frames"]}
    payloads = {identifier: bytes.fromhex(frame["payload_hex"]) for identifier, frame in frames.items()}
    emitted_rules = {finding["rule"] for finding in report["findings"]}
    coverage_rules = {entry["rule"] for entry in report["coverage"]["executed_rules"]}
    check("coverage lists exactly emitted rules", sorted(coverage_rules), sorted(emitted_rules))
    check("coverage unique rule count", report["coverage"]["unique_rule_count"], len(emitted_rules))
    check("coverage finding count", report["coverage"]["finding_count"], len(report["findings"]))

    for finding in report["findings"]:
        prefix = finding["rule"]
        evidence = finding["evidence"]
        # The report-level expected/actual fields are structured evidence, not
        # only the legacy "matching"/"mismatching" labels.  Keep this gate
        # explicit so a future refactor cannot silently drop the concrete
        # epoch, window, domain, identity and timestamp values.
        check(prefix + " expected is structured", isinstance(finding["expected"], dict), True)
        check(prefix + " actual is structured", isinstance(finding["actual"], dict), True)
        check(prefix + " expected frame ids", finding["expected"]["frame_ids"], finding["frames"])
        check(prefix + " actual frame ids", finding["actual"]["frame_ids"], finding["frames"])
        check(prefix + " actual concrete association keys", isinstance(finding["actual"]["association_keys"], list), True)
        check(prefix + " actual concrete field comparisons", isinstance(finding["actual"]["field_comparisons"], list), True)
        if finding["actual"]["summary"] in {"matching", "mismatching"}:
            check(prefix + " labelled verdict still carries referenced values", len(finding["actual"]["referenced_frames"]) > 0, True)
        check(prefix + " actual assumptions", evidence["supplied_assumptions"], case["assumptions"])
        check(prefix + " actual BMCA declaration", evidence["supplied_bmca_snapshot"], case["bmca"])
        check(prefix + " actual observation windows", evidence["observation_context"]["windows"], [
            {**window,
             "start": {"seconds": str(window["start"]["seconds"]), "nanoseconds": window["start"]["nanos"]},
             "end": {"seconds": str(window["end"]["seconds"]), "nanoseconds": window["end"]["nanos"]}}
            for window in case["observation"]["windows"]
        ])
        check(prefix + " reference rule", finding["rule_reference"]["rule"], prefix)
        check(prefix + " reference traceability", finding["rule_reference"]["rule_basis_document"], "docs/rule-traceability.md")
        check(prefix + " unresolved IDs", evidence["unresolved_frame_ids"], [])
        check(prefix + " ambiguous IDs", evidence["ambiguous_frame_ids"], [])
        check(prefix + " referenced IDs", [frame["id"] for frame in evidence["referenced_frames"]], finding["frames"])
        for frame in evidence["referenced_frames"]:
            identifier = frame["id"]
            payload = payloads[identifier]
            header = frame["header"]
            field_prefix = prefix + f" frame {identifier} "
            check(field_prefix + "source clock", header["source_port_identity"]["clock_identity_hex"], payload[20:28].hex())
            check(field_prefix + "source port", header["source_port_identity"]["port_number"], int.from_bytes(payload[28:30], "big"))
            check(field_prefix + "sequence", header["sequence_id"], int.from_bytes(payload[30:32], "big"))
            check(field_prefix + "domain", header["domain_number"], payload[4])
            check(field_prefix + "signed correction", header["correction_scaled_nanoseconds_decimal"], str(struct.unpack(">q", payload[8:16])[0]))
            check(field_prefix + "epoch", frame["observation"]["epoch"], frames[identifier]["epoch"])
            check(field_prefix + "window", frame["observation"]["window"], frames[identifier]["window"])
            wire_fields = {item["name"]: item for item in frame["wire_fields"]}
            for name, offset, length in [("sourcePortIdentity.clockIdentity", 20, 8), ("sourcePortIdentity.portNumber", 28, 2), ("sequenceId", 30, 2), ("correctionField", 8, 8)]:
                check(field_prefix + name + " byte offset", wire_fields[name]["byte_offset"], offset)
                check(field_prefix + name + " octet length", wire_fields[name]["octet_length"], length)

    measurement = report["measurements"][0]
    t1 = wire_time(payloads[2])
    t2 = timestamp(frames[1]["event_time"])
    t3 = timestamp(frames[3]["event_time"])
    t4 = wire_time(payloads[4])
    corrections = {identifier: struct.unpack(">q", payload[8:16])[0] for identifier, payload in payloads.items()}
    forward = (t2 - t1) * 65536 - corrections[1] - corrections[2]
    reverse = (t4 - t3) * 65536 - corrections[4]
    check("offset exact independent Fraction", Fraction(int(measurement["offset_numerator"]), measurement["denominator"]).__str__(), Fraction(forward - reverse, 131072).__str__())
    check("delay exact independent Fraction", Fraction(int(measurement["mean_delay_numerator"]), measurement["denominator"]).__str__(), Fraction(forward + reverse, 131072).__str__())
    check("forward intermediate", measurement["intermediate"]["forward_scaled_nanoseconds_decimal"], str(forward))
    check("reverse intermediate", measurement["intermediate"]["reverse_scaled_nanoseconds_decimal"], str(reverse))
    check("sync corrections intermediate", measurement["intermediate"]["sync_plus_follow_up_correction_scaled_nanoseconds_decimal"], str(corrections[1] + corrections[2]))
    check("response correction intermediate", measurement["intermediate"]["delay_response_correction_scaled_nanoseconds_decimal"], str(corrections[4]))
    for operand, value, identifier in zip(measurement["timestamps"], [t1, t2, t3, t4], [2, 1, 3, 4]):
        check(operand["name"] + " value", operand["value"]["total_nanoseconds_decimal"], str(value))
        check(operand["name"] + " source frame", operand["frame"], identifier)
    check("Delay_Req correction remains visible", measurement["corrections"][3]["signed_scaled_nanoseconds_decimal"], str(corrections[3]))
    check("Delay_Req correction not subtracted twice", measurement["corrections"][3]["subtracted_in_this_measurement"], False)

    absent = copy.deepcopy(case)
    for frame in absent["frames"]:
        frame.pop("epoch", None)
    absent_report, absent_code = run_cli(absent)
    (output / "missing-epoch-report.json").write_text(json.dumps(absent_report, indent=2) + "\n")
    check("missing epoch status", absent_report["status"], "InsufficientEvidence")
    check("missing epoch exit", absent_code, 3)
    check("missing epoch never measures", absent_report["measurements"], [])
    for finding in absent_report["findings"]:
        for frame in finding["evidence"]["referenced_frames"]:
            check("missing epoch remains null in evidence", frame["observation"]["epoch"], None)

    wrong = copy.deepcopy(case)
    response = bytearray.fromhex(wrong["frames"][3]["payload_hex"])
    response[52:54] = struct.pack(">H", 9)
    wrong["frames"][3]["payload_hex"] = response.hex()
    wrong_report, wrong_code = run_cli(wrong)
    (output / "wrong-requester-report.json").write_text(json.dumps(wrong_report, indent=2) + "\n")
    check("wrong requester status", wrong_report["status"], "Violation")
    check("wrong requester exit", wrong_code, 1)
    identity = next(finding for finding in wrong_report["findings"] if finding["rule"] == "CLAIM.E2E_IDENTITY")
    compared = next(item for item in identity["evidence"]["field_comparisons"] if item["field"].startswith("Delay_Resp.requestingPortIdentity"))
    check("requester concrete response port", compared["left_value"]["port_number"], 9)
    check("requester concrete request port", compared["right_value"]["port_number"], 1)
    check("requester comparison false", compared["equal"], False)
    check("wrong requester never measures", wrong_report["measurements"], [])

    manifest = {
        "verification": "shipping CLI report evidence v2",
        "scope": "constructed fixtures; no source-authenticity or normative certification claim",
        "fixture": str(fixture_path.relative_to(ROOT)),
        "fixture_sha256": digest(fixture_path),
        "verifier_sha256": digest(Path(__file__)),
        "checks": len(checks), "passed": sum(item["pass"] for item in checks),
        "all_passed": all(item["pass"] for item in checks),
        "details": checks,
        "reports": ["complete-report.json", "missing-epoch-report.json", "wrong-requester-report.json"],
    }
    (output / "verification.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    print(f"Report evidence v2: {len(checks)} checks passed across complete, missing-epoch and wrong-requester CLI cases")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
