#!/usr/bin/env python3
"""Verify shipping CLI operational examples with independent struct/Fraction math.

This verifier never imports the MoonBit implementation and never uses its output
as expected arithmetic. Synthetic fixture bytes, explicit caller bounds and
step records are the independent inputs. Outputs are retained for inspection.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import struct
import subprocess
import sys
from datetime import datetime, timezone
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DENOMINATOR = 131072
SCALE = 65536
EXIT = {"Pass": 0, "Violation": 1, "InsufficientEvidence": 3, "Unsupported": 4}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def sources():
    paths = list(ROOT.rglob("*.mbt")) + list(ROOT.rglob("*.mbti"))
    paths += [ROOT / "bin/ptp-audit.mjs", ROOT / "scripts/moon-local",
              ROOT / "scripts/build_commissioning_fixtures.py", Path(__file__).resolve()]
    return {str(p.relative_to(ROOT)): sha(p) for p in sorted(set(paths))
            if not any(part in ("_build", ".git", ".mooncakes") for part in p.relative_to(ROOT).parts)}


def ns(value):
    return int(value["seconds"]) * 1000000000 + value["nanos"]


def packet(frame):
    raw = bytes.fromhex(frame["payload_hex"])
    result = {"kind": raw[0] & 15, "domain": raw[4],
              "correction": struct.unpack_from(">q", raw, 8)[0],
              "source": {"clock": raw[20:28].hex(),
                         "port": struct.unpack_from(">H", raw, 28)[0]},
              "sequence": struct.unpack_from(">H", raw, 30)[0],
              "timestamp": int.from_bytes(raw[34:40], "big") * 1000000000
                           + struct.unpack_from(">I", raw, 40)[0]}
    if result["kind"] == 11:
        result.update(priority1=raw[47], clock_class=raw[48], accuracy=raw[49],
                      variance=struct.unpack_from(">H", raw, 50)[0], priority2=raw[52],
                      grandmaster=raw[53:61].hex(),
                      steps_removed=struct.unpack_from(">H", raw, 61)[0])
    return result


def reference(case):
    by_id = {f["id"]: f for f in case["frames"]}
    claim = case["exchanges"][0]
    fs = [by_id[claim[key]] for key in ("sync", "follow_up", "delay_req", "delay_resp")]
    s, f, q, r = [packet(frame) for frame in fs]
    forward_raw = (ns(fs[0]["event_time"]) - f["timestamp"]) * SCALE
    reverse_raw = (r["timestamp"] - ns(fs[2]["event_time"])) * SCALE
    forward = forward_raw - s["correction"] - f["correction"]
    reverse = reverse_raw - r["correction"]
    offset = Fraction(forward - reverse, DENOMINATOR)
    delay = Fraction(forward + reverse, DENOMINATOR)
    ledger = {
        "uncorrected_offset_numerator": str(forward_raw - reverse_raw),
        "uncorrected_delay_numerator": str(forward_raw + reverse_raw),
        "corrected_offset_numerator": str(forward - reverse),
        "corrected_delay_numerator": str(forward + reverse),
        "forward_raw_scaled": str(forward_raw), "reverse_raw_scaled": str(reverse_raw),
        "denominator": DENOMINATOR,
    }
    contributions = []
    for frame, p, sign, included, field in [
        (fs[0], s, -1, True, "Sync.correctionField"),
        (fs[1], f, -1, True, "Follow_Up.correctionField"),
        (fs[3], r, 1, True, "Delay_Resp.correctionField"),
        (fs[2], q, 0, False, "Delay_Req.correctionField"),
    ]:
        contributions.append({"frame": frame["id"], "field": field,
                              "correction_scaled": str(p["correction"]),
                              "offset_numerator": str(sign * p["correction"]),
                              "delay_numerator": str(-p["correction"] if included else 0),
                              "included": included, "denominator": DENOMINATOR})
    expected = {"frames": [x["id"] for x in fs], "ledger": ledger,
                "contributions": contributions, "offset_ns": str(offset),
                "mean_delay_ns": str(delay)}
    b = case.get("error_budget")
    if b and b.get("relative_rate_bound_confirmed") and b.get("source", "").strip() and b.get("assumptions", "").strip():
        values = b["timestamp_error_bounds_scaled"] + [b["correction_error_bound_scaled"], b["path_asymmetry_bound_scaled"]]
        valid = len(b["timestamp_error_bounds_scaled"]) == 4 and all(
            isinstance(v, str) and v.isascii() and v.isdecimal() and len(v) <= 256
            and (v == "0" or not v.startswith("0")) for v in values + [b["offset_limit_scaled"]])
        if valid:
            radius = Fraction(sum(int(v) for v in values), DENOMINATOR)
            limit = Fraction(int(b["offset_limit_scaled"]), SCALE)
            lower, upper = offset - radius, offset + radius
            verdict = "within_limit" if abs(offset) + radius <= limit else (
                "outside_limit" if lower > limit or upper < -limit else "indeterminate")
            expected["assessment"] = {
                "verdict": verdict,
                "lower_numerator": str(int(lower * DENOMINATOR)),
                "upper_numerator": str(int(upper * DENOMINATOR)),
                "radius_numerator": str(int(radius * DENOMINATOR)),
                "limit_numerator": str(int(limit * DENOMINATOR)),
                "denominator": DENOMINATOR,
            }
    return expected


def expected_selection(case):
    """Independent restricted comparator for these synthetic non-tie examples."""
    by_id = {f["id"]: f for f in case["frames"]}
    candidates = [(c, packet(by_id[c["frame"]])) for c in case["bmca"]["candidates"]]
    if len({p["grandmaster"] for _, p in candidates}) > 1:
        def key(item):
            p = item[1]
            return tuple(p[k] for k in ("priority1", "clock_class", "accuracy", "variance", "priority2", "grandmaster"))
    else:
        def key(item):
            p = item[1]
            return (p["steps_removed"], p["source"]["clock"], p["source"]["port"],
                    item[0]["receiver"]["port"])
    c, p = min(candidates, key=key)
    return {"candidate": c["id"], "announce_frame": c["frame"],
            "upstream_sender": p["source"], "receiver": c["receiver"],
            "grandmaster": p["grandmaster"], "domain": p["domain"]}


def declared_selection_conflicts(campaign):
    """Independently compare every declared interval, including nonadjacent ones.

    Used on the focused cases whose raw snapshots, stability and bindings all
    meet their premises; rejected steps are never treated as accepted here.
    """
    continuity = campaign.get("capture_clock_continuity", {})
    if not continuity.get("confirmed") or not continuity.get("source", "").strip():
        return []
    pairs = []
    for i, left in enumerate(campaign["steps"]):
        a = expected_selection(left["case"])
        a_snapshot = left["case"]["bmca"]["snapshot"]
        a_start = ns(a_snapshot["decision_time"])
        a_end = ns(left["selection_stability"]["until"])
        for right in campaign["steps"][i + 1:]:
            b = expected_selection(right["case"])
            b_snapshot = right["case"]["bmca"]["snapshot"]
            b_start = ns(b_snapshot["decision_time"])
            b_end = ns(right["selection_stability"]["until"])
            same_observer = (a["receiver"] == b["receiver"] and a["domain"] == b["domain"]
                             and a_snapshot["clock_domain"] == b_snapshot["clock_domain"])
            different_upstream = (a["upstream_sender"] != b["upstream_sender"]
                                  or a["grandmaster"] != b["grandmaster"])
            if same_observer and different_upstream and max(a_start, b_start) <= min(a_end, b_end):
                pairs.append([left["id"], right["id"]])
    return pairs


def all_findings(value):
    if isinstance(value, dict):
        if "rule" in value and "status" in value:
            yield value
        for nested in value.values():
            yield from all_findings(nested)
    elif isinstance(value, list):
        for nested in value:
            yield from all_findings(nested)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "research/commissioning")
    args = parser.parse_args()
    output = args.output.resolve(); output.mkdir(parents=True, exist_ok=True)
    fixture_manifest = ROOT / "fixtures/commissioning/manifest.json"
    manifest = json.loads(fixture_manifest.read_text())
    start_sources = sources()
    results, failures = [], []
    checks = 0

    def check(condition, description, details=None):
        nonlocal checks
        checks += 1
        if not condition:
            failures.append({"check": description, "details": details})

    def verify_math(case, report, name):
        expected = reference(case)
        metrology = report.get("metrology", [])
        check(len(metrology) == 1, name + ": one metrology ledger", len(metrology))
        if not metrology:
            return expected
        actual = metrology[0]
        check(actual.get("frames") == expected["frames"], name + ": ledger quartet identities")
        ledger = actual.get("ledger") or {}
        for key, value in expected["ledger"].items():
            check(ledger.get(key) == value, name + ": independent ledger " + key,
                  {"expected": value, "actual": ledger.get(key)})
        check(ledger.get("contributions") == expected["contributions"],
              name + ": signed PTP correction contribution ledger")
        if "assessment" in expected:
            assessment = actual.get("assessment") or {}
            for key, value in expected["assessment"].items():
                check(assessment.get(key) == value, name + ": independent Fraction interval " + key,
                      {"expected": value, "actual": assessment.get(key)})
            b = case["error_budget"]
            check(all(assessment.get("budget", {}).get(k) == v for k, v in b.items()),
                  name + ": report echoes this exact declared budget")
        else:
            check(actual.get("assessment") is None, name + ": no unsupported accuracy verdict")
        return expected

    for row in manifest["cases"]:
        path = ROOT / row["path"]
        check(sha(path) == row["sha256"], row["name"] + ": fixture content binding")
        command = [str(ROOT / "bin/ptp-audit.mjs"), row["command"], str(path), "--json"]
        # scripts/moon-local itself honors PTP_AUDIT_MOON as the underlying
        # compiler. Pointing that variable back to the wrapper recurses. The
        # shipping JS CLI uses the installed compiler, while native tests use
        # moon-local separately for its SDK selection.
        env = dict(os.environ)
        run = subprocess.run(command, cwd=ROOT, env=env, text=True, capture_output=True)
        report_path = output / (row["name"] + ".report.json")
        report_path.write_text(run.stdout)
        record = {"name": row["name"], "command": row["command"], "input": row["path"],
                  "input_sha256": sha(path), "report": str(report_path),
                  "report_sha256": sha(report_path), "expected_status": row["status"],
                  "process_exit": run.returncode, "stderr": run.stderr}
        try:
            report = json.loads(run.stdout)
        except json.JSONDecodeError:
            check(False, row["name"] + ": valid CLI JSON", {"stderr": run.stderr, "stdout": run.stdout[-1000:]})
            results.append(record)
            continue
        record["status"] = report.get("status")
        check(report.get("status") == row["status"], row["name"] + ": aggregate status", record)
        check(run.returncode == EXIT[row["status"]] == report.get("exit_code"),
              row["name"] + ": CLI exit status", record)
        rules = sorted({f["rule"] for f in all_findings(report)})
        record["rules"] = rules
        check(row["rule"] in rules, row["name"] + ": operational rule exercised", {"rule": row["rule"], "rules": rules})
        value = json.loads(path.read_text())
        if row["command"] == "check":
            record["independent_reference"] = verify_math(value, report, row["name"])
            verdict = row["expect"].get("verdict")
            if verdict is not None:
                assessment = report.get("metrology", [{}])[0].get("assessment") or {}
                check(assessment.get("verdict") == verdict, row["name"] + ": intended practical limit scenario")
        elif row["status"] == "Pass":
            returned_steps = report.get("steps", [])
            check(len(returned_steps) == len(value["steps"]), row["name"] + ": no step omitted")
            references = []
            for given, returned in zip(value["steps"], returned_steps):
                reference_selection = expected_selection(given["case"])
                references.append(reference_selection)
                selection = returned.get("selection") or {}
                for key, expected_value in reference_selection.items():
                    check(selection.get(key) == expected_value, row["name"] + ": independent BMCA selection " + key,
                          {"expected": expected_value, "actual": selection.get(key)})
                bindings = returned.get("bindings", [])
                check(len(bindings) == 1 and bindings[0].get("accepted") is True,
                      row["name"] + ": selected Announce bound to accepted quartet")
                if bindings:
                    actual_measurement = bindings[0].get("evidence", {}).get("measurement", {})
                    math = reference(given["case"])
                    check(actual_measurement.get("offset_numerator") == math["ledger"]["corrected_offset_numerator"],
                          row["name"] + ": binding retains independent exact offset")
                verify_math(given["case"], returned.get("case_report", {}), row["name"] + "/" + given["id"])
            transitions = report.get("transitions", [])
            expected_transitions = row["expect"].get("transitions", [row["expect"].get("transition")])
            check([t.get("classification") for t in transitions] == expected_transitions,
                  row["name"] + ": actual sender/GM transition classification", transitions)
            record["independent_selection"] = references
            operational = row["expect"].get("operational_acceptance", "unassessed")
            check(report.get("operational_acceptance") == operational,
                  row["name"] + ": deployment verdict remains separate from protocol evidence status",
                  report.get("operational_acceptance"))
        elif row["name"] == "old-master-after-switch":
            steps = report.get("steps", [])
            check(len(steps) == 2 and steps[1].get("case_report", {}).get("status") == "Pass",
                  "stale master: quartet itself is internally valid PTP")
            check(len(steps) == 2 and any(not b.get("accepted") for b in steps[1].get("bindings", [])),
                  "stale master: commissioning rejects valid quartet from wrong selected upstream")
        if row["expect"].get("rejected_middle"):
            transitions = report.get("transitions", [])
            check(len(transitions) == 2 and
                  [(t.get("from_step"), t.get("to_step")) for t in transitions] ==
                  [("before-change", "rejected-middle"), ("rejected-middle", "after-rejected-step")],
                  "rejected step is retained in adjacent transition chain")
            check(all(t.get("status") == "InsufficientEvidence" and t.get("classification") is None
                      for t in transitions), "no accepted transition bridges the rejected middle step")
        if row["name"] == "contradictory-overlapping-selection":
            transitions = report.get("transitions", [])
            check(len(transitions) == 1 and transitions[0].get("status") == "Violation"
                  and transitions[0].get("classification") is None,
                  "overlapping incompatible selection declarations cannot yield a transition")
        if "conflict_pairs" in row["expect"]:
            independent_pairs = declared_selection_conflicts(value)
            check(independent_pairs == row["expect"]["conflict_pairs"],
                  row["name"] + ": independent all-pairs closed-interval reference", independent_pairs)
            actual_conflicts = report.get("selection_conflicts", [])
            actual_pairs = [[c.get("from_step"), c.get("to_step")] for c in actual_conflicts]
            check(actual_pairs == independent_pairs,
                  row["name"] + ": all selection conflicts including nonadjacent pairs are reported",
                  {"expected": independent_pairs, "actual": actual_pairs})
            check(all(c.get("finding", {}).get("rule") == "COMMISSION.TRANSITION.CONTRADICTORY_STABILITY"
                      and c.get("finding", {}).get("status") == "Violation"
                      and c.get("evidence", {}).get("transition_inferred") is False
                      for c in actual_conflicts),
                  row["name"] + ": conflicts report contradictions without inventing transitions")
            if independent_pairs:
                returned_steps = report.get("steps", [])
                check(len(returned_steps) == len(value["steps"]) and
                      all(s.get("status") == "Pass" and s.get("case_report", {}).get("status") == "Pass"
                          and len(s.get("bindings", [])) == 1 and s["bindings"][0].get("accepted") is True
                          for s in returned_steps),
                      row["name"] + ": all individual snapshots and quartet bindings remain valid")
                check(report.get("operational_acceptance") == "evidence_not_accepted",
                      row["name"] + ": globally contradictory selection evidence is rejected")
                expected_adjacent = row["expect"]["adjacent_pairs"]
                actual_adjacent = [[t.get("from_step"), t.get("to_step")] for t in report.get("transitions", [])]
                check(actual_adjacent == expected_adjacent,
                      row["name"] + ": global conflicts do not replace adjacent transitions", actual_adjacent)
            record["independent_selection_conflicts"] = independent_pairs
        results.append(record)
        print(f"{row['name']}: expected={row['status']} actual={report.get('status')} exit={run.returncode}")

    independent_review = ROOT / "research/commissioning/nonadjacent-independent-review-input.json"
    independent_review_record = None
    check(independent_review.exists(), "independent review original counterexample is available")
    if independent_review.exists():
        # Preserve and run the independent reviewer's original counterexample,
        # rather than relying only on a newly constructed lookalike fixture.
        expected_sha = "29fe63b136af29cbc122334dff7f832a8ed12a6b69086e9bf4d230170320e8dd"
        check(sha(independent_review) == expected_sha,
              "independent review original counterexample byte binding")
        original = json.loads(independent_review.read_text())
        generated = json.loads((ROOT / "fixtures/commissioning/nonadjacent-contradictory-selection.json").read_text())
        check(original["steps"] == generated["steps"],
              "generated nonadjacent regression preserves original independent step evidence")
        original_conflicts = declared_selection_conflicts(original)
        check(original_conflicts == [["long-A", "new-B"]],
              "original review input independently contradicts its first and third selections")
        run = subprocess.run([str(ROOT / "bin/ptp-audit.mjs"), "commission", str(independent_review), "--json"],
                             cwd=ROOT, text=True, capture_output=True)
        original_report = output / "nonadjacent-independent-review.report.json"
        original_report.write_text(run.stdout)
        independent_review_record = {"input": str(independent_review.relative_to(ROOT)),
                                     "input_sha256": sha(independent_review),
                                     "report": str(original_report),
                                     "report_sha256": sha(original_report),
                                     "process_exit": run.returncode,
                                     "independent_conflict_pairs": original_conflicts}
        try:
            actual = json.loads(run.stdout)
            check(run.returncode == 1 and actual.get("status") == "Violation" and
                  actual.get("operational_acceptance") == "evidence_not_accepted",
                  "independent review exact original now rejects contradictory campaign")
            check([[c.get("from_step"), c.get("to_step")] for c in actual.get("selection_conflicts", [])]
                  == original_conflicts,
                  "independent review exact original reports nonadjacent first/third conflict")
        except json.JSONDecodeError:
            check(False, "independent review exact original returns JSON", run.stderr)

    ending_sources = sources()
    check(start_sources == ending_sources, "source bindings unchanged throughout independent run")
    summary = {"schema": "ptp-operational-verification/v1",
               "generated_at": datetime.now(timezone.utc).isoformat(),
               "status": "pass" if not failures else "fail", "checks": checks,
               "fixture_count": len(manifest["cases"]),
               "fixture_manifest": str(fixture_manifest.relative_to(ROOT)),
               "fixture_manifest_sha256": sha(fixture_manifest),
               "independent_method": "Python network-order struct decode and fractions.Fraction from fixture inputs; no MoonBit imports or result-derived expected values.",
               "provenance": "All inputs are explicitly synthetic, not hardware captures; declared bounds are not authenticated calibration.",
               "source_bindings": start_sources,
               "sources_unchanged_during_run": start_sources == ending_sources,
               "cases": results, "independent_review_regression": independent_review_record,
               "failures": failures}
    (output / "manifest.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n")
    print(f"Independent operational verification: {summary['status']}; {checks} checks; {len(results)} fixtures")
    if failures:
        print(json.dumps(failures, ensure_ascii=False, indent=2))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
