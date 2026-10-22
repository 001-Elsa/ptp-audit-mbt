#!/usr/bin/env python3
"""Construct synthetic PTP commissioning inputs without running the application.

The bytes are produced with Python struct, not by the MoonBit encoder.  They are
operational examples and counterexamples, not captures from physical hardware.
Run scripts/verify_commissioning.py for independent Fraction arithmetic checks.
"""
from __future__ import annotations

import copy
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "fixtures" / "commissioning"
MASTER_A = "0011223344556677"
MASTER_B = "0011223344556678"
SLAVE = "8899aabbccddeeff"
SYNTHETIC = "Synthetic network-order bytes constructed by Python struct; no physical capture or hardware accuracy claim."


def port(clock=MASTER_A, number=1):
    return {"clock": clock, "port": number}


def stamp(seconds, nanos=0):
    return {"seconds": str(seconds), "nanos": nanos}


def identity(value):
    return bytes.fromhex(value["clock"]) + struct.pack(">H", value["port"])


def payload(kind, *, source=MASTER_A, seq=7, correction=0, seconds=100,
            nanos=0, grandmaster=None, priority1=100, steps_removed=0):
    length = {0: 44, 8: 44, 1: 44, 9: 54, 11: 64}[kind]
    flags = 0x0200 if kind == 0 else 0
    header = struct.pack(">BBHBBHqI", kind, 2, length, 0, 0, flags,
                         correction, 0)
    header += identity(port(source))
    header += struct.pack(">HBb", seq, {0: 0, 8: 2, 1: 1, 9: 3, 11: 5}[kind], 0)
    body = seconds.to_bytes(6, "big") + struct.pack(">I", nanos)
    if kind == 9:
        body += identity(port(SLAVE))
    elif kind == 11:
        body += struct.pack(">hBBBBHB", 37, 0, priority1, 248, 0x22,
                            0x4321, 128)
        body += bytes.fromhex(grandmaster or source)
        body += struct.pack(">HB", steps_removed, 0xA0)
    assert len(header + body) == length
    return (header + body).hex()


def audit_case(*, seconds=100, epoch=0, master=MASTER_A, winner="A",
               same_gm=False, request_correction=999999):
    window = f"commission-window-{epoch}"
    clock = "synthetic-slave-monotonic-0"
    frames = []
    for frame_id, kind, nanos, capture_nanos, correction in [
        (1, 0, 0, 1300, -32768), (2, 8, 1000, 2000, 16384),
        (3, 1, 5000, 5000, request_correction), (4, 9, 5250, 5250, 49152),
    ]:
        frame = {
            "id": frame_id, "epoch": epoch, "window": window,
            "payload_hex": payload(kind, source=SLAVE if kind == 1 else master,
                                   seq=31 if kind in (1, 9) else 7,
                                   correction=correction, seconds=seconds,
                                   nanos=nanos),
            "capture_time": stamp(seconds, capture_nanos),
            "capture_clock_domain": clock,
        }
        if kind in (0, 1):
            frame.update(local_port=port(SLAVE),
                         event_time=stamp(seconds, 1300 if kind == 0 else 5000),
                         clock_domain=clock, direction="rx" if kind == 0 else "tx")
        frames.append(frame)
    for frame_id, source, candidate in [(5, MASTER_A, "A"), (6, MASTER_B, "B")]:
        frames.append({
            "id": frame_id, "epoch": epoch, "window": window,
            "payload_hex": payload(11, source=source, seconds=seconds,
                                   grandmaster=MASTER_A if same_gm else source,
                                   priority1=100 if same_gm or candidate == winner else 120,
                                   steps_removed=0 if candidate == winner else (2 if same_gm else 0)),
            "capture_time": stamp(seconds, 0), "capture_clock_domain": clock,
        })
    return {
        "schema": "ptp-audit/v1", "profile": "default-e2e-two-step-2008",
        "frames": frames,
        "observation": {
            "windows": [{"id": window, "epoch": epoch, "clock_domain": clock,
                         "start": stamp(seconds, 0), "end": stamp(seconds, 100000),
                         "complete": True}],
            "policy": {"source": "synthetic-commissioning-lab-policy",
                       "sync_follow_up_ns": 1000000000,
                       "delay_response_ns": 1000000000},
        },
        "pair_claims": [{"sync": 1, "follow_up": 2}],
        "exchanges": [{"sync": 1, "follow_up": 2, "delay_req": 3, "delay_resp": 4}],
        "assumptions": {"symmetric_path": True, "timestamp_provenance": True,
                        "stable_rates": True},
        "bmca": {
            "candidates": [{"id": candidate, "frame": frame_id, "receiver": port(SLAVE)}
                           for candidate, frame_id in [("A", 5), ("B", 6)]],
            "selected": winner, "candidates_complete": True,
            "eligibility_confirmed": True,
            "snapshot": {"epoch": epoch, "window": window,
                         "clock_domain": clock, "decision_time": stamp(seconds, 500),
                         "announce_validity_ns": 1000000000,
                         "validity_source": "synthetic-explicit-announce-window",
                         "validity_confirmed": True, "capture_window_confirmed": True},
        },
    }


def step(case, name):
    return {"id": name, "case": case,
            "selection_stability": {"source": "synthetic-lab-controller-selection-record",
                                    "confirmed": True,
                                    "until": copy.deepcopy(case["observation"]["windows"][0]["end"])}}


def commission(*, same_gm=False, stale=False):
    return {
        "schema": "ptp-commission/v1",
        "capture_clock_continuity": {"source": "synthetic-single-slave-clock-lab-record",
                                     "confirmed": True},
        "steps": [step(audit_case(same_gm=same_gm), "before-change"),
                  step(audit_case(seconds=101, epoch=1,
                                  master=MASTER_A if stale else MASTER_B,
                                  winner="B", same_gm=same_gm), "after-change")],
    }


def budget(*, limit="3276800", timestamps=None, correction="0", asymmetry="0"):
    return {"timestamp_error_bounds_scaled": timestamps or ["0"] * 4,
            "correction_error_bound_scaled": correction,
            "path_asymmetry_bound_scaled": asymmetry,
            "offset_limit_scaled": limit,
            "source": "synthetic-explicit-lab-bounds-not-device-calibration",
            "assumptions": "Independent declared upper bounds; rate stability already confirmed for this short exchange.",
            "relative_rate_bound_confirmed": True}


def build():
    OUT.mkdir(parents=True, exist_ok=True)
    rows = []

    def save(name, value, command, status, rule, **expect):
        path = OUT / (name + ".json")
        raw = (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode()
        path.write_bytes(raw)
        rows.append({"name": name, "path": str(path.relative_to(ROOT)),
                     "command": command, "status": status, "rule": rule,
                     "sha256": hashlib.sha256(raw).hexdigest(),
                     "provenance": SYNTHETIC, "expect": expect})

    save("grandmaster-switch", commission(), "commission", "Pass",
         "COMMISSION.TRANSITION.OBSERVED", transition="upstream_port_and_grandmaster_changed")
    save("old-master-after-switch", commission(stale=True), "commission", "Violation",
         "COMMISSION.BINDING.IDENTITY", stale_step="after-change")
    save("same-grandmaster-sender-switch", commission(same_gm=True), "commission", "Pass",
         "COMMISSION.TRANSITION.OBSERVED", transition="upstream_port_changed_same_grandmaster")
    c = commission()
    c["steps"][1]["case"] = audit_case(seconds=101, epoch=1)
    c["steps"][1]["selection_stability"]["until"] = stamp(101, 100000)
    save("stable-master", c, "commission", "Pass", "COMMISSION.TRANSITION.OBSERVED",
         transition="unchanged")
    c = commission(); c.pop("capture_clock_continuity")
    save("missing-clock-continuity", c, "commission", "InsufficientEvidence",
         "COMMISSION.TRANSITION.EVIDENCE")
    c = commission(); c["capture_clock_continuity"]["confirmed"] = False
    save("unconfirmed-clock-continuity", c, "commission", "InsufficientEvidence",
         "COMMISSION.TRANSITION.EVIDENCE")
    c = commission(); c["steps"][1].pop("selection_stability")
    save("missing-selection-stability", c, "commission", "InsufficientEvidence",
         "COMMISSION.STABILITY.EVIDENCE")
    c = commission(); c["steps"][1]["selection_stability"]["confirmed"] = False
    save("unconfirmed-selection-stability", c, "commission", "InsufficientEvidence",
         "COMMISSION.STABILITY.EVIDENCE")
    c = commission(); c["steps"][1]["selection_stability"]["until"] = stamp(101, 5200)
    save("selection-stability-ends-early", c, "commission", "Violation",
         "COMMISSION.BINDING.VALIDITY")
    c = commission(); c["steps"][1]["case"]["bmca"]["snapshot"]["decision_time"] = stamp(101, 6000)
    save("exchange-before-decision", c, "commission", "Violation",
         "COMMISSION.BINDING.VALIDITY")
    c = commission(); c["steps"][1]["case"]["bmca"]["snapshot"]["decision_time"] = stamp(101, 100001)
    save("decision-outside-window", c, "commission", "InsufficientEvidence",
         "COMMISSION.CASE")
    c = commission(); c["steps"][1]["case"]["bmca"]["candidates_complete"] = False
    save("incomplete-candidates", c, "commission", "InsufficientEvidence",
         "COMMISSION.CASE")
    c = commission(); c["steps"][1]["id"] = "before-change"
    save("duplicate-step-id", c, "commission", "Violation", "COMMISSION.INPUT.SCHEMA")
    c = commission(); c["unexpected"] = True
    save("unknown-input-field", c, "commission", "Violation", "COMMISSION.INPUT.SCHEMA")
    c = commission(); c["steps"].reverse()
    save("reversed-step-order", c, "commission", "InsufficientEvidence",
         "COMMISSION.TRANSITION.EVIDENCE")
    c = commission(); c["steps"][1]["case"]["frames"][0]["clock_domain"] = "unrelated-event-clock"
    save("mixed-event-clock", c, "commission", "InsufficientEvidence", "COMMISSION.CASE")
    c = commission(); c["steps"][1]["case"].pop("bmca")
    save("missing-bmca", c, "commission", "InsufficientEvidence", "COMMISSION.SELECTION.EVIDENCE")
    c = commission(); c["steps"] = []
    save("empty-steps", c, "commission", "Violation", "COMMISSION.INPUT.SCHEMA")
    c = commission(); c["steps"] = c["steps"] * 9
    save("too-many-steps", c, "commission", "Unsupported", "COMMISSION.INPUT.RESOURCE")
    c = commission(); c["steps"][1]["selection_stability"]["until"] = stamp(102, 0)
    save("stability-outside-window", c, "commission", "Violation", "COMMISSION.STABILITY.WINDOW")
    c = commission()
    for candidate in c["steps"][1]["case"]["bmca"]["candidates"]:
        candidate["receiver"] = port("8899aabbccddee00")
    save("different-observer-port", c, "commission", "Violation", "COMMISSION.BINDING.IDENTITY")
    c = commission()
    isolated = copy.deepcopy(c["steps"][1]["case"]["observation"]["windows"][0])
    isolated.update(id="isolated-exchange-window", epoch=2)
    c["steps"][1]["case"]["observation"]["windows"].append(isolated)
    for frame in c["steps"][1]["case"]["frames"][:4]:
        frame.update(epoch=2, window="isolated-exchange-window")
    save("isolated-exchange-context", c, "commission", "Violation", "COMMISSION.BINDING.CONTEXT")
    c = commission(); c["steps"][1]["case"]["exchanges"] = []
    c["steps"][1]["case"]["pair_claims"] = []
    c["steps"][1]["case"]["frames"] = c["steps"][1]["case"]["frames"][4:]
    save("no-accepted-quartet", c, "commission", "InsufficientEvidence", "COMMISSION.BINDING.EVIDENCE")
    c = commission(); c["steps"][1]["case"]["frames"][5]["payload_hex"] = payload(
        11, source=MASTER_A, seconds=101, grandmaster=MASTER_B, priority1=100)
    # The next step can retain the same immediate sender while its GM dataset changes.
    c["steps"][1]["case"]["frames"][0]["payload_hex"] = payload(0, source=MASTER_A, seconds=101, correction=-32768)
    c["steps"][1]["case"]["frames"][1]["payload_hex"] = payload(8, source=MASTER_A, seconds=101, nanos=1000, correction=16384)
    c["steps"][1]["case"]["frames"][3]["payload_hex"] = payload(9, source=MASTER_A, seconds=101, seq=31, nanos=5250, correction=49152)
    save("same-sender-new-grandmaster", c, "commission", "Pass", "COMMISSION.TRANSITION.OBSERVED",
         transition="upstream_grandmaster_changed")
    c = commission()
    c["steps"][0]["case"]["observation"]["windows"][0]["end"] = stamp(101, 1000)
    c["steps"][0]["selection_stability"]["until"] = stamp(101, 1000)
    save("contradictory-overlapping-selection", c, "commission", "Violation",
         "COMMISSION.TRANSITION.CONTRADICTORY_STABILITY")
    c = commission()
    rejected = step(audit_case(seconds=101, epoch=1, master=MASTER_A, winner="B"),
                    "rejected-middle")
    last = step(audit_case(seconds=102, epoch=2, master=MASTER_B, winner="B"),
                "after-rejected-step")
    c["steps"] = [c["steps"][0], rejected, last]
    save("rejected-middle-is-not-skipped", c, "commission", "Violation",
         "COMMISSION.TRANSITION.EVIDENCE", rejected_middle=True)
    c = commission()
    long_a = step(audit_case(), "long-A")
    long_a["case"]["observation"]["windows"][0]["end"] = stamp(104)
    long_a["selection_stability"]["until"] = stamp(104)
    short_a = step(audit_case(seconds=101, epoch=1), "short-A")
    new_b = step(audit_case(seconds=102, epoch=2, master=MASTER_B, winner="B"), "new-B")
    c["steps"] = [long_a, short_a, new_b]
    save("nonadjacent-contradictory-selection", c, "commission", "Violation",
         "COMMISSION.TRANSITION.CONTRADICTORY_STABILITY",
         conflict_pairs=[["long-A", "new-B"]],
         adjacent_pairs=[["long-A", "short-A"], ["short-A", "new-B"]])
    c = copy.deepcopy(c)
    c["steps"][0]["selection_stability"]["until"] = stamp(100, 100000)
    c["steps"][0]["case"]["observation"]["windows"][0]["end"] = stamp(100, 100000)
    save("nonadjacent-selection-safe-control", c, "commission", "Pass",
         "COMMISSION.TRANSITION.OBSERVED", conflict_pairs=[],
         transitions=["unchanged", "upstream_port_and_grandmaster_changed"])
    for name, value, verdict in [
        ("commissioning-within-offset-budget", budget(), "within_limit"),
        ("commissioning-outside-offset-budget", budget(limit="655360"), "outside_limit"),
        ("commissioning-indeterminate-offset-budget",
         budget(limit="1671168", timestamps=["65536"] * 4), "indeterminate"),
    ]:
        c = commission()
        for s in c["steps"]: s["case"]["error_budget"] = copy.deepcopy(value)
        save(name, c, "commission", "Pass", "COMMISSION.BINDING.ACCEPTED",
             transition="upstream_port_and_grandmaster_changed", operational_acceptance=verdict)

    def metrology(name, b=None, status="Pass", verdict=None, mutator=None):
        case = audit_case()
        case.pop("bmca"); case["frames"] = case["frames"][:4]
        if b is not None: case["error_budget"] = b
        if mutator: mutator(case)
        save("metrology-" + name, case, "check", status,
             "METROLOGY.LEDGER" if b is None else "METROLOGY.ERROR_BUDGET",
             verdict=verdict)

    metrology("ledger-only")
    metrology("within-limit", budget(), verdict="within_limit")
    metrology("outside-limit", budget(limit="655360"), verdict="outside_limit")
    metrology("uncertain-boundary", budget(limit="1671168", timestamps=["65536"] * 4),
              verdict="indeterminate")
    metrology("exact-positive-limit", budget(limit="1671168"), verdict="within_limit")
    metrology("exact-negative-limit", budget(limit="1671168"), verdict="within_limit",
              mutator=lambda c: c["frames"][0].update(event_time=stamp(100, 1198)))
    metrology("interval-touches-positive-limit", budget(limit="1703936", correction="65536"),
              verdict="within_limit")
    metrology("interval-crosses-positive-limit", budget(limit="1671168", correction="65536"),
              verdict="indeterminate")
    metrology("interval-touches-outside-edge", budget(limit="1638400", correction="65536"),
              verdict="indeterminate")
    metrology("declared-asymmetry-bound", budget(asymmetry="131072"), verdict="within_limit")
    metrology("max-256-digit-bound", budget(correction="9" * 256), verdict="indeterminate")
    metrology("request-correction-invariant", budget(), verdict="within_limit",
              mutator=lambda c: c["frames"][2].update(payload_hex=payload(1, source=SLAVE,
                       seq=31, correction=-123456789, seconds=100, nanos=5000)))
    for name, field, value, status in [
        ("blank-source", "source", "  ", "InsufficientEvidence"),
        ("blank-assumptions", "assumptions", "", "InsufficientEvidence"),
        ("unconfirmed-rate", "relative_rate_bound_confirmed", False, "InsufficientEvidence"),
        ("negative-bound", "correction_error_bound_scaled", "-1", "Violation"),
        ("noncanonical-bound", "path_asymmetry_bound_scaled", "01", "Violation"),
        ("oversized-bound", "correction_error_bound_scaled", "9" * 257, "Violation"),
        ("short-timestamp-array", "timestamp_error_bounds_scaled", ["0"] * 3, "Violation"),
    ]:
        b = budget(); b[field] = value; metrology(name, b, status)
    for field in ["source", "assumptions", "relative_rate_bound_confirmed"]:
        b = budget(); b.pop(field)
        metrology("missing-" + field.replace("_", "-"), b, "InsufficientEvidence")
    manifest = {"schema": "ptp-operational-fixtures/v1",
                "generator": "scripts/build_commissioning_fixtures.py",
                "provenance": SYNTHETIC, "cases": rows}
    (OUT / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    print(f"Constructed {len(rows)} operational synthetic fixtures in {OUT}")


if __name__ == "__main__":
    build()
