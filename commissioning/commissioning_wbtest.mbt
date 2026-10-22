///|
fn test_stamp(seconds : Int32, nanos : Int32) -> Json {
  Json::object({
    "seconds": Json::string(seconds.to_string()),
    "nanos": Json::number(nanos.to_double()),
  })
}

///|
fn test_object(value : Json) -> Map[String, Json] {
  match value {
    Object(m) => m
    _ => abort("test object required")
  }
}

///|
fn test_array(value : Json) -> Array[Json] {
  match value {
    Array(a) => a
    _ => abort("test array required")
  }
}

///|
fn test_payload(
  kind : @wire.Kind,
  source : @wire.PortIdentity,
  body : @wire.Body,
) -> String {
  let packet : @wire.Packet = {
    header: {
      kind,
      source,
      domain: 0,
      flags: if kind == @wire.Sync {
        512
      } else {
        0
      },
      correction: 0L,
      sequence: if kind == @wire.DelayReq || kind == @wire.DelayResp {
        31
      } else {
        7
      },
      log_interval: 0,
    },
    body,
  }
  match @wire.encode(packet) {
    Ok(bytes) => @wire.to_hex(bytes)
    Err(e) => abort(e.code)
  }
}

///|
fn test_case(
  sender_clock : String,
  grandmaster : String,
  seconds : Int32,
  capture_clock : String,
) -> Json {
  let sender : @wire.PortIdentity = { clock: sender_clock, port: 1, }
  let receiver : @wire.PortIdentity = { clock: "8899aabbccddeeff", port: 1, }
  let data : @wire.AnnounceData = {
    origin: { seconds: 100L, nanos: 0, },
    utc_offset: 37,
    priority1: 100,
    clock_class: 248,
    accuracy: 34,
    variance: 17185,
    priority2: 128,
    grandmaster,
    steps_removed: 0,
    time_source: 160,
  }
  let payloads = [
    test_payload(
      @wire.Sync,
      sender,
      @wire.TimestampBody({ seconds: 100L, nanos: 0, }),
    ),
    test_payload(
      @wire.FollowUp,
      sender,
      @wire.TimestampBody({ seconds: 100L, nanos: 1000, }),
    ),
    test_payload(
      @wire.DelayReq,
      receiver,
      @wire.TimestampBody({ seconds: 100L, nanos: 5000, }),
    ),
    test_payload(
      @wire.DelayResp,
      sender,
      @wire.Response({ seconds: 100L, nanos: 5250, }, receiver),
    ),
    test_payload(@wire.Announce, sender, @wire.Announcement(data)),
  ]
  let frames = []
  let captures = [1000, 2000, 5000, 6000, 0]
  for i = 0; i < 5; i = i + 1 {
    let m = Map([
      ("id", Json::number((i + 1).to_double())),
      ("epoch", Json::number(0.0)),
      ("window", Json::string("capture")),
      ("capture_clock_domain", Json::string(capture_clock)),
      ("capture_time", test_stamp(seconds, captures[i])),
      ("payload_hex", Json::string(payloads[i])),
    ])
    if i == 0 || i == 2 {
      m.set("local_port", identity(receiver))
      m.set("event_time", test_stamp(100, if i == 0 { 1300 } else { 5000 }))
      m.set("clock_domain", Json::string("slave-ptp-clock"))
      m.set("direction", Json::string(if i == 0 { "rx" } else { "tx" }))
    }
    frames.push(Json::object(m))
  }
  Json::object({
    "schema": Json::string("ptp-audit/v1"),
    "profile": Json::string("default-e2e-two-step-2008"),
    "frames": Json::array(frames),
    "pair_claims": Json::array([
      Json::object({ "sync": Json::number(1.0), "follow_up": Json::number(2.0) }),
    ]),
    "exchanges": Json::array([
      Json::object({
        "sync": Json::number(1.0),
        "follow_up": Json::number(2.0),
        "delay_req": Json::number(3.0),
        "delay_resp": Json::number(4.0),
      }),
    ]),
    "assumptions": Json::object({
      "symmetric_path": Json::boolean(true),
      "timestamp_provenance": Json::boolean(true),
      "stable_rates": Json::boolean(true),
    }),
    "observation": Json::object({
      "windows": Json::array([
        Json::object({
          "id": Json::string("capture"),
          "epoch": Json::number(0.0),
          "clock_domain": Json::string(capture_clock),
          "start": test_stamp(seconds, 0),
          "end": test_stamp(seconds + 1, 0),
          "complete": Json::boolean(true),
        }),
      ]),
      "policy": Json::object({
        "source": Json::string("synthetic-test-policy"),
        "sync_follow_up_ns": Json::number(1000000.0),
        "delay_response_ns": Json::number(1000000.0),
      }),
    }),
    "bmca": Json::object({
      "candidates": Json::array([
        Json::object({
          "id": Json::string("A"),
          "frame": Json::number(5.0),
          "receiver": identity(receiver),
        }),
      ]),
      "selected": Json::string("A"),
      "candidates_complete": Json::boolean(true),
      "eligibility_confirmed": Json::boolean(true),
      "snapshot": Json::object({
        "epoch": Json::number(0.0),
        "window": Json::string("capture"),
        "clock_domain": Json::string(capture_clock),
        "decision_time": test_stamp(seconds, 100),
        "announce_validity_ns": Json::number(1000000000.0),
        "validity_source": Json::string("synthetic-test-validity"),
        "validity_confirmed": Json::boolean(true),
        "capture_window_confirmed": Json::boolean(true),
      }),
    }),
  })
}

///|
fn test_step(
  id : String,
  sender : String,
  gm : String,
  seconds : Int32,
  clock : String,
) -> Json {
  Json::object({
    "id": Json::string(id),
    "case": test_case(sender, gm, seconds, clock),
    "selection_stability": Json::object({
      "source": Json::string("synthetic-device-selection-log"),
      "confirmed": Json::boolean(true),
      "until": test_stamp(seconds, 10000),
    }),
  })
}

///|
fn test_campaign(steps : Array[Json]) -> Json {
  Json::object({
    "schema": Json::string("ptp-commission/v1"),
    "steps": Json::array(steps),
    "capture_clock_continuity": Json::object({
      "source": Json::string("synthetic-single-monotonic-clock"),
      "confirmed": Json::boolean(true),
    }),
  })
}

///|
fn test_snapshot(step : Json) -> Map[String, Json] {
  let c = test_object(test_object(step)["case"])
  test_object(test_object(c["bmca"])["snapshot"])
}

///|
test "selected upstream quartet binding retains independent raw arithmetic" {
  let step = test_step(
    "before", "0011223344556677", "1022334455667788", 100, "capture-clock",
  )
  let report = audit(test_campaign([step]).stringify())
  assert_eq(report.status().label(), "Pass")
  assert_eq(report.steps.length(), 1)
  assert_eq(report.steps[0].bindings.length(), 1)
  assert_eq(
    report.steps[0].case_report.measurements[0].offset_numerator,
    "3276800",
  )
  assert_eq(report.steps[0].case_report.measurements[0].denominator, 131072)
  assert_eq(report.transitions.length(), 0)
  let selected = report.steps[0].selection.unwrap()
  assert_eq(selected.sender.clock, "0011223344556677")
  assert_eq(selected.grandmaster, "1022334455667788")
  assert_eq(report.exit_code(), 0)
  assert_true(
    audit_json(test_campaign([step]).stringify()).contains(
      "ptp-commission-report/v1",
    ),
  )
}

///|
test "upstream sender and grandmaster identity changes remain distinct" {
  let before = test_step(
    "before", "0011223344556677", "1022334455667788", 100, "capture-clock",
  )
  let same = test_step(
    "same", "0011223344556677", "1022334455667788", 101, "capture-clock",
  )
  let same_gm = test_step(
    "port", "0011223344556678", "1022334455667788", 102, "capture-clock",
  )
  let same_port = test_step(
    "gm", "0011223344556678", "1022334455667789", 103, "capture-clock",
  )
  let both = test_step(
    "both", "0011223344556679", "1022334455667790", 104, "capture-clock",
  )
  let report = audit(
    test_campaign([before, same, same_gm, same_port, both]).stringify(),
  )
  assert_eq(report.status().label(), "Pass")
  assert_eq(report.transitions.map(fn(t) { t.classification.unwrap() }), [
    "unchanged", "upstream_port_changed_same_grandmaster", "upstream_grandmaster_changed",
    "upstream_port_and_grandmaster_changed",
  ])
}

///|
test "missing or unconfirmed selection stability cannot bind arithmetic" {
  for
    stability in [
      Json::null(),
      Json::object({ "confirmed": Json::boolean(false) }),
      Json::object({
        "confirmed": Json::boolean(true),
        "source": Json::string(" "),
        "until": test_stamp(100, 10000),
      }),
    ] {
    let step = test_step(
      "missing", "0011223344556677", "0011223344556677", 100, "capture-clock",
    )
    let m = test_object(step)
    if stability == Json::null() {
      m.remove("selection_stability")
    } else {
      m.set("selection_stability", stability)
    }
    let report = audit(test_campaign([step]).stringify())
    assert_eq(report.status().label(), "InsufficientEvidence")
    assert_eq(report.steps[0].case_report.measurements.length(), 1)
    assert_eq(report.steps[0].bindings.length(), 0)
    assert_eq(report.exit_code(), 3)
  }
}

///|
test "confirmed interval contradictions reject bindings while retaining raw measurement" {
  for
    mode in [
      "future-decision", "expired-announce", "early-until", "outside-window",
    ] {
    let step = test_step(
      mode, "0011223344556677", "0011223344556677", 100, "capture-clock",
    )
    let snapshot = test_snapshot(step)
    match mode {
      "future-decision" => snapshot.set("decision_time", test_stamp(100, 7000))
      "expired-announce" =>
        snapshot.set("announce_validity_ns", Json::number(500.0))
      "early-until" =>
        test_object(test_object(step)["selection_stability"]).set(
          "until",
          test_stamp(100, 500),
        )
      _ =>
        test_object(test_object(step)["selection_stability"]).set(
          "until",
          test_stamp(102, 0),
        )
    }
    let report = audit(test_campaign([step]).stringify())
    assert_eq(report.status().label(), "Violation")
    assert_eq(report.steps[0].case_report.status().label(), "Pass")
    assert_eq(report.steps[0].case_report.measurements.length(), 1)
    assert_eq(report.exit_code(), 1)
  }
}

///|
test "selected Announce sender mismatch cannot accept a valid exchange" {
  let step = test_step(
    "wrong-master", "0011223344556677", "0011223344556677", 100, "capture-clock",
  )
  let frames = test_array(test_object(test_object(step)["case"])["frames"])
  let announce = test_object(frames[4])
  let packet = @wire.decode(
    @wire.from_hex(text(announce["payload_hex"]) catch { _ => "" }).unwrap(),
  ).unwrap()
  let changed = {
    ..packet,
    header: {
      ..packet.header,
      source: { clock: "0011223344556678", port: 1, },
    },
  }
  announce.set(
    "payload_hex",
    Json::string(@wire.to_hex(@wire.encode(changed).unwrap())),
  )
  let report = audit(test_campaign([step]).stringify())
  assert_eq(report.steps[0].case_report.status().label(), "Pass")
  assert_eq(report.status().label(), "Violation")
  assert_true(
    report.steps[0].bindings[0].findings.any(fn(f) {
      f.rule == "COMMISSION.BINDING.IDENTITY"
    }),
  )
}

///|
test "clock continuity chronology and rejected steps gate adjacent transitions" {
  let before = test_step(
    "before", "0011223344556677", "0011223344556677", 100, "capture-clock",
  )
  let after = test_step(
    "after", "0011223344556678", "0011223344556678", 101, "different-capture-clock",
  )
  let cross_clock = audit(test_campaign([before, after]).stringify())
  assert_eq(cross_clock.steps[0].case_report.status().label(), "Pass")
  assert_eq(cross_clock.steps[1].case_report.status().label(), "Pass")
  assert_eq(cross_clock.status().label(), "InsufficientEvidence")
  assert_true(cross_clock.transitions[0].classification is None)
  let overlap = test_step(
    "overlap", "0011223344556678", "0011223344556678", 100, "capture-clock",
  )
  let overlap_report = audit(test_campaign([before, overlap]).stringify())
  assert_eq(overlap_report.status().label(), "Violation")
  assert_eq(overlap_report.selection_conflicts.length(), 1)
  assert_true(overlap_report.transitions[0].classification is None)
  let no_continuity = test_campaign([
    before,
    test_step(
      "next", "0011223344556678", "0011223344556678", 101, "capture-clock",
    ),
  ])
  test_object(no_continuity).remove("capture_clock_continuity")
  assert_eq(
    audit(no_continuity.stringify()).status().label(),
    "InsufficientEvidence",
  )
  let rejected = test_step(
    "rejected", "0011223344556678", "0011223344556678", 101, "capture-clock",
  )
  test_object(rejected).remove("selection_stability")
  let last = test_step(
    "last", "0011223344556679", "0011223344556679", 102, "capture-clock",
  )
  let report = audit(test_campaign([before, rejected, last]).stringify())
  assert_eq(report.transitions.length(), 2)
  assert_true(report.transitions.all(fn(t) { t.classification is None }))
}

///|
test "campaign input is strict bounded and duplicate-safe" {
  let step = test_step(
    "same", "0011223344556677", "0011223344556677", 100, "capture-clock",
  )
  assert_eq(audit(test_campaign([]).stringify()).status().label(), "Violation")
  assert_eq(
    audit(test_campaign([step, step]).stringify()).status().label(),
    "Violation",
  )
  let extra = test_campaign([step])
  test_object(extra).set("surprise", Json::boolean(true))
  assert_eq(audit(extra.stringify()).status().label(), "Violation")
  assert_eq(
    audit(
      "{\"schema\":\"ptp-commission/v1\",\"schema\":\"ptp-commission/v1\",\"steps\":[]}",
    )
    .status()
    .label(),
    "Violation",
  )
  let entries = []
  for i = 0; i < 17; i = i + 1 {
    entries.push(
      test_step(
        "s" + i.to_string(),
        "0011223344556677",
        "0011223344556677",
        100,
        "capture-clock",
      ),
    )
  }
  assert_eq(
    audit(test_campaign(entries).stringify()).status().label(),
    "Unsupported",
  )
}

///|
test "different snapshot domain rejects an independently valid exchange" {
  let step = test_step(
    "wrong-domain", "0011223344556677", "0011223344556677", 100, "capture-clock",
  )
  let frames = test_array(test_object(test_object(step)["case"])["frames"])
  for i = 0; i < 4; i = i + 1 {
    let frame = test_object(frames[i])
    let packet = @wire.decode(
      @wire.from_hex(text(frame["payload_hex"]) catch { _ => "" }).unwrap(),
    ).unwrap()
    let changed = { ..packet, header: { ..packet.header, domain: 1, }, }
    frame.set(
      "payload_hex",
      Json::string(@wire.to_hex(@wire.encode(changed).unwrap())),
    )
  }
  let report = audit(test_campaign([step]).stringify())
  assert_eq(report.steps[0].case_report.status().label(), "Pass")
  assert_eq(report.status().label(), "Violation")
  assert_true(
    report.steps[0].bindings[0].findings.any(fn(f) {
      f.rule == "COMMISSION.BINDING.CONTEXT"
    }),
  )
}

///|
test "overlapping declared upstream selection intervals contradict a transition" {
  let before = test_step(
    "before", "0011223344556677", "0011223344556677", 100, "capture-clock",
  )
  let after = test_step(
    "after", "0011223344556678", "0011223344556678", 100, "capture-clock",
  )
  let after_frames = test_array(
    test_object(test_object(after)["case"])["frames"],
  )
  // Two disjoint observed quartets but simultaneous assertions of exclusive selection.
  for i = 0; i < 5; i = i + 1 {
    test_object(after_frames[i]).set(
      "capture_time",
      test_stamp(100, if i == 4 { 4000 } else { 11000 + i * 1000 }),
    )
  }
  test_snapshot(after).set("decision_time", test_stamp(100, 5000))
  test_object(test_object(after)["selection_stability"]).set(
    "until",
    test_stamp(100, 20000),
  )
  let report = audit(test_campaign([before, after]).stringify())
  assert_eq(
    report.steps.map(fn(s) { @diagnostic.summarize(s.findings).label() }),
    ["Pass", "Pass"],
  )
  assert_eq(report.status().label(), "Violation")
  assert_eq(
    report.transitions[0].finding.rule,
    "COMMISSION.TRANSITION.CONTRADICTORY_STABILITY",
  )
  assert_true(report.transitions[0].classification is None)
}

///|
test "binding acceptance does not imply any configured timing acceptance" {
  let step = test_step(
    "plain", "0011223344556677", "0011223344556677", 100, "capture-clock",
  )
  let campaign = test_campaign([step])
  assert_eq(audit(campaign.stringify()).operational_acceptance(), "unassessed")
  let c = test_object(test_object(step)["case"])
  c.set(
    "error_budget",
    Json::object({
      "source": Json::string("synthetic-zero-error-demonstration"),
      "assumptions": Json::string(
        "Synthetic timestamps, exact correction, symmetric paths and no rate error; not calibration.",
      ),
      "relative_rate_bound_confirmed": Json::boolean(true),
      "timestamp_error_bounds_scaled": Json::array([
        Json::string("0"),
        Json::string("0"),
        Json::string("0"),
        Json::string("0"),
      ]),
      "correction_error_bound_scaled": Json::string("0"),
      "path_asymmetry_bound_scaled": Json::string("0"),
      "offset_limit_scaled": Json::string("655360"),
    }),
  )
  let outside = audit(campaign.stringify())
  assert_eq(outside.status().label(), "Pass")
  assert_eq(outside.operational_acceptance(), "outside_limit")
  test_object(c["error_budget"]).set(
    "offset_limit_scaled",
    Json::string("6553600"),
  )
  assert_eq(
    audit(campaign.stringify()).operational_acceptance(),
    "within_limit",
  )
  test_object(c["error_budget"]).set(
    "timestamp_error_bounds_scaled",
    Json::array([
      Json::string("10000000"),
      Json::string("10000000"),
      Json::string("10000000"),
      Json::string("10000000"),
    ]),
  )
  assert_eq(
    audit(campaign.stringify()).operational_acceptance(),
    "indeterminate",
  )
}

///|
test "campaign rejects nonadjacent contradictory stability without inferring a nonadjacent transition" {
  let long_a = test_step(
    "long-A", "0011223344556677", "0011223344556677", 100, "capture-clock",
  )
  let short_a = test_step(
    "short-A", "0011223344556677", "0011223344556677", 101, "capture-clock",
  )
  let b = test_step(
    "B", "0011223344556678", "0011223344556678", 102, "capture-clock",
  )
  // Extend the first observation window so this long assertion is itself valid.
  let c = test_object(test_object(long_a)["case"])
  let windows = test_array(test_object(c["observation"])["windows"])
  test_object(windows[0]).set("end", test_stamp(105, 0))
  test_object(test_object(long_a)["selection_stability"]).set(
    "until",
    test_stamp(104, 0),
  )
  let campaign = test_campaign([long_a, short_a, b])
  let report = audit(campaign.stringify())
  assert_true(
    report.steps.all(fn(s) {
      @diagnostic.summarize(s.findings) == @diagnostic.Pass
    }),
  )
  assert_true(
    report.transitions.all(fn(t) { t.finding.status == @diagnostic.Pass }),
  )
  assert_eq(report.transitions.length(), 2)
  assert_eq(report.status().label(), "Violation")
  assert_eq(report.operational_acceptance(), "evidence_not_accepted")
  assert_eq(report.selection_conflicts.length(), 1)
  let conflict = report.selection_conflicts[0]
  assert_eq(conflict.from_step, "long-A")
  assert_eq(conflict.to_step, "B")
  let json = test_object(report.to_json())
  let conflicts = test_array(json["selection_conflicts"])
  let finding = test_object(test_object(conflicts[0])["finding"])
  assert_eq(finding["from_step"], Json::string("long-A"))
  assert_eq(finding["to_step"], Json::string("B"))
  assert_true(
    test_array(json["findings"]).any(fn(v) {
      test_object(v).get("from_step") == Some(Json::string("long-A")) &&
      test_object(v).get("to_step") == Some(Json::string("B"))
    }),
  )
  // A prior interval ending strictly before B's decision is consistent.
  test_object(test_object(long_a)["selection_stability"]).set(
    "until",
    test_stamp(101, 500000000),
  )
  let safe = audit(campaign.stringify())
  assert_eq(safe.status().label(), "Pass")
  assert_eq(safe.selection_conflicts.length(), 0)
  // No continuity assertion permits no cross-clock contradiction conclusion.
  test_object(test_object(long_a)["selection_stability"]).set(
    "until",
    test_stamp(104, 0),
  )
  test_object(campaign).remove("capture_clock_continuity")
  let unconfirmed = audit(campaign.stringify())
  assert_eq(unconfirmed.status().label(), "InsufficientEvidence")
  assert_eq(unconfirmed.selection_conflicts.length(), 0)
}
