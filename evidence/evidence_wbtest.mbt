///|
fn field_value(value : Json, key : String) -> Json {
  match value {
    Object(fields) => fields.get(key).unwrap()
    _ => Json::null()
  }
}

///|
fn element(value : Json, index : Int32) -> Json {
  match value {
    Array(items) => items[index]
    _ => Json::null()
  }
}

///|
fn test_frame(id : Int32, kind : @wire.Kind) -> @exchange.Frame {
  let master : @wire.PortIdentity = { clock: "0011223344556677", port: 1, }
  let slave : @wire.PortIdentity = { clock: "8899aabbccddeeff", port: 2, }
  {
    id,
    epoch: Some(5),
    window: Some("capture-5"),
    capture_time: Some({ seconds: 100L, nanos: id * 10, }),
    capture_clock_domain: Some("capture-monotonic"),
    packet: {
      header: {
        kind,
        domain: 7,
        flags: 512,
        correction: -32768L,
        source: if kind == @wire.DelayReq {
          slave
        } else {
          master
        },
        sequence: if kind == @wire.DelayReq || kind == @wire.DelayResp {
          9
        } else {
          65535
        },
        log_interval: -1,
      },
      body: if kind == @wire.DelayResp {
        @wire.Response({ seconds: 100L, nanos: 5250, }, slave)
      } else {
        @wire.TimestampBody({ seconds: 100L, nanos: 1000, })
      },
    },
    local_port: Some(slave),
    event_time: Some({
      seconds: 100L,
      nanos: if kind == @wire.Sync {
        1300
      } else {
        5000
      },
    }),
    clock_domain: Some("slave-phc0"),
    direction: Some(if kind == @wire.Sync { "rx" } else { "tx" }),
  }
}

///|
test "wire evidence preserves signed correction, maximum timestamp and field offsets" {
  let sample = test_frame(1, @wire.FollowUp)
  let frame : @exchange.Frame = {
    ..sample,
    packet: {
      ..sample.packet,
      body: @wire.TimestampBody({ seconds: 281474976710655L, nanos: 999999999, }),
    },
  }
  let evidence = frame_json(frame)
  assert_eq(
    field_value(
      field_value(evidence, "header"),
      "correction_scaled_nanoseconds_decimal",
    ),
    Json::string("-32768"),
  )
  let stamp = field_value(field_value(evidence, "body"), "timestamp")
  assert_eq(
    field_value(stamp, "seconds_decimal"),
    Json::string("281474976710655"),
  )
  assert_eq(
    field_value(stamp, "total_nanoseconds_decimal"),
    Json::string("281474976710655999999999"),
  )
  let fields = field_value(evidence, "wire_fields")
  assert_eq(field_value(element(fields, 7), "byte_offset"), Json::number(8))
  assert_eq(field_value(element(fields, 7), "octet_length"), Json::number(8))
  assert_eq(
    field_value(element(fields, 14), "name"),
    Json::string("preciseOriginTimestamp.secondsField"),
  )
}

///|
test "association evidence exposes absent epoch, wrong requester and real supplied assumptions" {
  let s = test_frame(1, @wire.Sync)
  let f = test_frame(2, @wire.FollowUp)
  let q = test_frame(3, @wire.DelayReq)
  let r0 = test_frame(4, @wire.DelayResp)
  let r : @exchange.Frame = {
    ..r0,
    epoch: None,
    packet: {
      ..r0.packet,
      body: @wire.Response({ seconds: 100L, nanos: 5250, }, {
        clock: "ffeeddccbbaa9988",
        port: 3,
      }),
    },
  }
  let finding = @diagnostic.finding(
    "CLAIM.E2E_IDENTITY",
    @diagnostic.Violation,
    [1, 2, 3, 4],
    Some(20),
    "matching requester",
    "mismatching",
    "Explicit claim.",
  )
  let assumptions = Json::object({ "symmetric_path": Json::boolean(false) })
  let context : @observation.Context = { windows: [], policy: None, }
  let encoded = finding_json(finding, [s, f, q, r], context, assumptions, None)
  let evidence = field_value(encoded, "evidence")
  assert_eq(field_value(evidence, "supplied_assumptions"), assumptions)
  let keys = field_value(evidence, "association_keys")
  assert_eq(field_value(element(keys, 3), "epoch"), Json::null())
  let comparisons = field_value(evidence, "field_comparisons")
  match comparisons {
    Array(values) => {
      let requester = values.filter(fn(value) {
        field_value(value, "field") ==
        Json::string(
          "Delay_Resp.requestingPortIdentity vs Delay_Req.sourcePortIdentity",
        )
      })
      assert_eq(requester.length(), 1)
      assert_eq(field_value(requester[0], "equal"), Json::boolean(false))
      assert_eq(
        field_value(field_value(requester[0], "left_value"), "port_number"),
        Json::number(3),
      )
      assert_eq(
        field_value(field_value(requester[0], "right_value"), "port_number"),
        Json::number(2),
      )
    }
    _ => abort("comparison evidence missing")
  }
}

///|
test "measurement evidence keeps the correction operands and exact intermediate quantities" {
  let m : @exchange.Measurement = {
    frames: [1, 2, 3, 4],
    offset_numerator: "3342336",
    delay_numerator: "36012032",
    denominator: 131072,
    forward_scaled: "19677184",
    reverse_scaled: "16334848",
    sync_correction_scaled: "-16384",
    delay_correction_scaled: "49152",
  }
  let f = test_frame(2, @wire.FollowUp)
  let q = test_frame(3, @wire.DelayReq)
  let r = test_frame(4, @wire.DelayResp)
  let corrected_f : @exchange.Frame = {
    ..f,
    packet: { ..f.packet, header: { ..f.packet.header, correction: 16384L, }, },
  }
  let corrected_q : @exchange.Frame = {
    ..q,
    packet: { ..q.packet, header: { ..q.packet.header, correction: 999999L, }, },
  }
  let corrected_r : @exchange.Frame = {
    ..r,
    packet: { ..r.packet, header: { ..r.packet.header, correction: 49152L, }, },
  }
  let encoded = measurement_json(m, [
    test_frame(1, @wire.Sync),
    corrected_f,
    corrected_q,
    corrected_r,
  ])
  assert_eq(field_value(encoded, "offset_numerator"), Json::string("3342336"))
  assert_eq(field_value(encoded, "denominator"), Json::number(131072))
  assert_eq(
    field_value(
      field_value(encoded, "intermediate"),
      "forward_scaled_nanoseconds_decimal",
    ),
    Json::string("19677184"),
  )
  let timestamps = field_value(encoded, "timestamps")
  assert_eq(field_value(element(timestamps, 0), "frame"), Json::number(2))
  assert_eq(
    field_value(element(timestamps, 1), "event_clock_domain"),
    Json::string("slave-phc0"),
  )
  assert_eq(field_value(element(timestamps, 1), "byte_offset"), Json::null())
  let corrections = field_value(encoded, "corrections")
  assert_eq(
    field_value(element(corrections, 3), "subtracted_in_this_measurement"),
    Json::boolean(false),
  )
  assert_eq(
    field_value(element(corrections, 3), "signed_scaled_nanoseconds_decimal"),
    Json::string("999999"),
  )
  assert_eq(
    field_value(element(corrections, 0), "signed_scaled_nanoseconds_decimal"),
    Json::string("-32768"),
  )
}

///|
test "coverage deduplicates rule status pairs and does not imply unexecuted BMCA success" {
  let pass = @diagnostic.finding(
    "CLAIM.SYNC_FOLLOW_UP",
    @diagnostic.Pass,
    [1, 2],
    None,
    "same",
    "same",
    "",
  )
  let insufficient = @diagnostic.finding(
    "CLAIM.SYNC_FOLLOW_UP",
    @diagnostic.InsufficientEvidence,
    [3, 4],
    None,
    "same",
    "missing",
    "",
  )
  let encoded = coverage_json([pass, pass, insufficient])
  assert_eq(field_value(encoded, "unique_rule_count"), Json::number(1))
  let rule = element(field_value(encoded, "executed_rules"), 0)
  assert_eq(field_value(rule, "execution_count"), Json::number(3))
  assert_eq(
    field_value(rule, "statuses"),
    Json::array([Json::string("Pass"), Json::string("InsufficientEvidence")]),
  )
  match field_value(encoded, "unreported_rule_families") {
    Array(families) => assert_true(families.contains(Json::string("BMCA.")))
    _ => abort("coverage missing")
  }
  let policy_ref = rule_reference_json("OBSERVATION.WINDOW")
  assert_eq(field_value(policy_ref, "standard"), Json::null())
  assert_eq(
    field_value(policy_ref, "classification"),
    Json::string("project_evidence_or_scope_policy"),
  )
}

///|
test "per-rule official evidence keeps scope exclusions distinct from certified normative claims" {
  let excluded = rule_reference_json("SCOPE.CORRECTION_TOO_BIG")
  assert_eq(
    field_value(excluded, "classification"),
    Json::string("project_evidence_or_scope_policy"),
  )
  assert_eq(field_value(excluded, "standard"), Json::null())
  let sentinel_sources = field_value(excluded, "reviewed_official_evidence")
  assert_eq(
    field_value(element(sentinel_sources, 0), "locator"),
    Json::string("Interpretation #25, page 21; interpretation #27, pages 23-24"),
  )
  let two_step = rule_reference_json("WIRE.TWO_STEP_FLAG")
  match field_value(two_step, "reviewed_official_evidence") {
    Array(facts) =>
      assert_true(
        facts.any(fn(fact) {
          field_value(fact, "locator") ==
          Json::string("Interpretation #11, page 7")
        }),
      )
    _ => abort("two-step evidence missing")
  }
  let gm = rule_reference_json("BMCA.DIFFERENT_GM.priority1")
  assert_eq(
    field_value(
      element(field_value(gm, "reviewed_official_evidence"), 0),
      "locator",
    ),
    Json::string("Interpretation #31, page 28; Figure 27 / Clause 9.3.4"),
  )
  let topology = rule_reference_json("BMCA.SAME_GM.oneHop")
  assert_eq(
    field_value(
      element(field_value(topology, "reviewed_official_evidence"), 0),
      "evidence_level",
    ),
    Json::string("reviewed_non_normative_tutorial"),
  )
}

///|
test "reference surfaces distinguish typed variants from protocol encoding and identify reviewed bytes" {
  let body_kind = rule_reference_json("WIRE.BODY_KIND")
  assert_eq(
    field_value(body_kind, "classification"),
    Json::string("project_evidence_or_scope_policy"),
  )
  assert_eq(
    field_value(body_kind, "precise_basis_classification"),
    Json::string("project_typed_input_variant_policy"),
  )
  assert_eq(
    field_value(body_kind, "input_surface"),
    Json::string("typed_api_encode"),
  )
  assert_eq(field_value(body_kind, "standard"), Json::null())
  assert_eq(
    field_value(body_kind, "reviewed_official_evidence"),
    Json::array([]),
  )
  for
    rule in [
      "WIRE.FIELD_RANGE", "WIRE.ANNOUNCE", "WIRE.RESPONSE", "WIRE.TIMESTAMP",
    ] {
    let reference = rule_reference_json(rule)
    assert_eq(
      field_value(reference, "precise_basis_classification"),
      Json::string("typed_protocol_representation_boundary"),
    )
    assert_eq(
      field_value(reference, "input_surface"),
      Json::string("typed_api_encode"),
    )
  }
  let nanos = rule_reference_json("WIRE.NANOSECONDS")
  assert_eq(
    field_value(nanos, "input_surface"),
    Json::string("wire_payload_decode"),
  )
  match field_value(nanos, "reviewed_official_evidence") {
    Array(facts) => {
      let tutorial = facts.filter(fn(fact) {
        field_value(fact, "source_id") ==
        Json::string("ieee802-garner-1588v2-tutorial-2008")
      })
      assert_eq(tutorial.length(), 1)
      assert_eq(
        field_value(tutorial[0], "sha256"),
        Json::string(
          "a023d1d55e20fe4b3ea5dbf11cdcfd650abfa071c3cab11e8247de6ff4eece68",
        ),
      )
      assert_eq(
        field_value(tutorial[0], "evidence_level"),
        Json::string("reviewed_non_normative_tutorial"),
      )
    }
    _ => abort("timestamp tutorial evidence missing")
  }
  let upstream = element(field_value(nanos, "upstream_sources"), 0)
  assert_eq(
    field_value(upstream, "source_id"),
    Json::string("linuxptp-v4.4-msg-h"),
  )
  assert_eq(
    field_value(upstream, "sha256"),
    Json::string(
      "4fcb3192f77ca15ab848857f21854bf3ac3d3d849ce47b97b071180cbb387c55",
    ),
  )
}
