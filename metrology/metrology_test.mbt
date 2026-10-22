///|
fn quartet() -> Array[@exchange.Frame] {
  let master : @wire.PortIdentity = { clock: "000000000000000a", port: 1, }
  let slave : @wire.PortIdentity = { clock: "000000000000000b", port: 2, }
  [@wire.Sync, @wire.FollowUp, @wire.DelayReq, @wire.DelayResp].mapi(fn(
    index,
    kind,
  ) {
    let time : @wire.PtpTimestamp = {
      seconds: 100L,
      nanos: [1300, 1000, 1600, 1900][index],
    }
    {
      id: index + 1,
      epoch: Some(9),
      window: Some("calibration-run"),
      capture_time: Some({ seconds: 100L, nanos: index * 1000, }),
      capture_clock_domain: Some("capture-clock"),
      packet: {
        header: {
          kind,
          domain: 0,
          flags: if kind == @wire.Sync {
            512
          } else {
            0
          },
          correction: [65536L, -32768L, 999999L, 131072L][index],
          source: if kind == @wire.DelayReq {
            slave
          } else {
            master
          },
          sequence: if kind == @wire.Sync || kind == @wire.FollowUp {
            10
          } else {
            20
          },
          log_interval: 0,
        },
        body: if kind == @wire.DelayResp {
          @wire.Response(time, slave)
        } else {
          @wire.TimestampBody(time)
        },
      },
      local_port: Some(slave),
      event_time: Some(time),
      clock_domain: Some("slave-clock"),
      direction: Some(if kind == @wire.DelayReq { "tx" } else { "rx" }),
    }
  })
}

///|
fn measurement() -> @exchange.Measurement {
  {
    frames: [1, 2, 3, 4],
    offset_numerator: "98304",
    delay_numerator: "39157760",
    denominator: 131072,
    forward_scaled: "19628032",
    reverse_scaled: "19529728",
    sync_correction_scaled: "32768",
    delay_correction_scaled: "131072",
  }
}

///|
fn budget() -> @metrology.ErrorBudget {
  {
    timestamp_error_bounds_scaled: ["0", "0", "0", "0"],
    correction_error_bound_scaled: "0",
    path_asymmetry_bound_scaled: "0",
    offset_limit_scaled: "49152",
    source: "Synthetic independent test vector",
    assumptions: "Per-event timestamp bounds include relative-rate error for this exchange; asymmetry bound is supplied, not inferred.",
    relative_rate_bound_confirmed: true,
  }
}

///|
test "PTP ledger exposes separate signed corrections and excludes Delay Req" {
  let out = @metrology.explain(measurement(), quartet(), None)
  assert_eq(out.status.label(), "Pass")
  assert_true(out.assessment is None)
  let ledger = out.ledger.unwrap()
  assert_eq(ledger.uncorrected_offset_numerator, "0")
  assert_eq(ledger.uncorrected_delay_numerator, "39321600")
  assert_eq(ledger.corrected_offset_numerator, "98304")
  assert_eq(ledger.corrected_delay_numerator, "39157760")
  assert_eq(ledger.contributions[0].offset_numerator, "-65536")
  assert_eq(ledger.contributions[1].offset_numerator, "32768")
  assert_eq(ledger.contributions[2].offset_numerator, "131072")
  assert_eq(ledger.contributions[2].delay_numerator, "-131072")
  assert_eq(ledger.contributions[3].correction_scaled, "999999")
  assert_eq(ledger.contributions[3].offset_numerator, "0")
  assert_eq(ledger.contributions[3].delay_numerator, "0")
  assert_true(!ledger.contributions[3].included)
}

///|
test "PTP zero radius exact limit is inclusive within" {
  let assessment = @metrology.explain(measurement(), quartet(), Some(budget())).assessment.unwrap()
  assert_eq(assessment.verdict, "within_limit")
  assert_eq(assessment.lower_numerator, "98304")
  assert_eq(assessment.upper_numerator, "98304")
  assert_eq(assessment.limit_numerator, "98304")
}

///|
test "PTP interval one scaled step beyond limit is conditionally outside" {
  let assessment = @metrology.explain(
    measurement(),
    quartet(),
    Some({ ..budget(), offset_limit_scaled: "49151", }),
  ).assessment.unwrap()
  assert_eq(assessment.verdict, "outside_limit")
}

///|
test "PTP all six bound operands form radius and touching limit is indeterminate" {
  let out = @metrology.explain(
    measurement(),
    quartet(),
    Some({
      ..budget(),
      timestamp_error_bounds_scaled: ["1", "2", "3", "4"],
      correction_error_bound_scaled: "5",
      path_asymmetry_bound_scaled: "7",
      offset_limit_scaled: "49163",
    }),
  )
  let assessment = out.assessment.unwrap()
  assert_eq(assessment.radius_numerator, "22")
  assert_eq(assessment.lower_numerator, "98282")
  assert_eq(assessment.upper_numerator, "98326")
  assert_eq(assessment.verdict, "within_limit")
  let touching = @metrology.explain(
    measurement(),
    quartet(),
    Some({
      ..budget(),
      timestamp_error_bounds_scaled: ["1", "2", "3", "4"],
      correction_error_bound_scaled: "5",
      path_asymmetry_bound_scaled: "7",
      offset_limit_scaled: "49141",
    }),
  ).assessment.unwrap()
  assert_eq(touching.lower_numerator, touching.limit_numerator)
  assert_eq(touching.verdict, "indeterminate")
}

///|
test "PTP negative offset outside and touching boundaries retain signs" {
  let fs = quartet()
  fs[0] = {
    ..fs[0],
    packet: {
      ..fs[0].packet,
      header: { ..fs[0].packet.header, correction: 131072L, },
    },
  }
  fs[3] = {
    ..fs[3],
    packet: {
      ..fs[3].packet,
      header: { ..fs[3].packet.header, correction: 0L, },
    },
  }
  let m : @exchange.Measurement = {
    ..measurement(),
    offset_numerator: "-98304",
    delay_numerator: "39223296",
    forward_scaled: "19562496",
    reverse_scaled: "19660800",
    sync_correction_scaled: "98304",
    delay_correction_scaled: "0",
  }
  let exact = @metrology.explain(m, fs, Some(budget())).assessment.unwrap()
  assert_eq(exact.verdict, "within_limit")
  let outside = @metrology.explain(
    m,
    fs,
    Some({ ..budget(), offset_limit_scaled: "49151", }),
  ).assessment.unwrap()
  assert_eq(outside.verdict, "outside_limit")
  let overlap = @metrology.explain(
    m,
    fs,
    Some({
      ..budget(),
      path_asymmetry_bound_scaled: "2",
      offset_limit_scaled: "49151",
    }),
  ).assessment.unwrap()
  assert_eq(overlap.verdict, "indeterminate")
  assert_eq(overlap.upper_numerator, "-98302")
}

///|
test "PTP missing rate or bound provenance preserves ledger without verdict" {
  for
    b in [
      { ..budget(), source: " ", },
      { ..budget(), assumptions: "", },
      { ..budget(), relative_rate_bound_confirmed: false, },
    ] {
    let out = @metrology.explain(measurement(), quartet(), Some(b))
    assert_eq(out.status.label(), "InsufficientEvidence")
    assert_true(out.ledger is Some(_))
    assert_true(out.assessment is None)
  }
}

///|
test "PTP budget rejects malformed and negative decimal bounds without throwing" {
  for invalid in ["", "-1", "+1", "01", "-0", " 1", "1.0", "1e9", "0x10", "１"] {
    let out = @metrology.explain(
      measurement(),
      quartet(),
      Some({ ..budget(), correction_error_bound_scaled: invalid, }),
    )
    assert_eq(out.status.label(), "Violation")
    assert_true(out.ledger is Some(_))
    assert_true(out.assessment is None)
  }
  let wrong_count = @metrology.explain(
    measurement(),
    quartet(),
    Some({ ..budget(), timestamp_error_bounds_scaled: ["0", "0", "0"], }),
  )
  assert_eq(wrong_count.status.label(), "Violation")
  let invalid_limit = @metrology.explain(
    measurement(),
    quartet(),
    Some({ ..budget(), offset_limit_scaled: "-1", }),
  )
  assert_eq(invalid_limit.status.label(), "Violation")
}

///|
test "PTP BigInt bounds exceed machine integers and remain exact" {
  let huge = "1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
  let out = @metrology.explain(
    measurement(),
    quartet(),
    Some({
      ..budget(),
      path_asymmetry_bound_scaled: huge,
      offset_limit_scaled: huge,
    }),
  )
  assert_eq(out.status.label(), "Pass")
  assert_eq(out.assessment.unwrap().radius_numerator, huge)
  assert_eq(out.assessment.unwrap().verdict, "within_limit")
}

///|
test "PTP maximum wire timestamp and signed correction extremes use BigInt operands" {
  // Literal expected values independently calculated with Python integers:
  // raw=(2**48-1)*10**9*65536; Sync.c=-2**63; Resp.c=2**63-2.
  let fs = quartet()
  let zero : @wire.PtpTimestamp = { seconds: 0L, nanos: 0, }
  let far : @wire.PtpTimestamp = { seconds: 281474976710655L, nanos: 0, }
  fs[0] = {
    ..fs[0],
    event_time: Some(far),
    packet: {
      ..fs[0].packet,
      header: { ..fs[0].packet.header, correction: -9223372036854775808L, },
    },
  }
  fs[1] = {
    ..fs[1],
    packet: {
      body: @wire.TimestampBody(zero),
      header: { ..fs[1].packet.header, correction: 0L, },
    },
  }
  fs[2] = { ..fs[2], event_time: Some(zero), }
  fs[3] = {
    ..fs[3],
    packet: {
      body: @wire.Response(far, fs[2].packet.header.source),
      header: { ..fs[3].packet.header, correction: 9223372036854775806L, },
    },
  }
  let m : @exchange.Measurement = {
    ..measurement(),
    offset_numerator: "18446744073709551614",
    delay_numerator: "36893488147418972160000000002",
    forward_scaled: "18446744082932858116854775808",
    reverse_scaled: "18446744064486114043145224194",
    sync_correction_scaled: "-9223372036854775808",
    delay_correction_scaled: "9223372036854775806",
  }
  let out = @metrology.explain(m, fs, None)
  assert_eq(out.status.label(), "Pass")
  let ledger = out.ledger.unwrap()
  assert_eq(ledger.forward_raw_scaled, "18446744073709486080000000000")
  assert_eq(ledger.reverse_raw_scaled, "18446744073709486080000000000")
  assert_eq(ledger.uncorrected_offset_numerator, "0")
  assert_eq(ledger.contributions[0].offset_numerator, "9223372036854775808")
  assert_eq(ledger.contributions[2].offset_numerator, "9223372036854775806")
}

///|
test "PTP decimal input cap rejects 257 characters before BigInt allocation" {
  let oversized = "1" + String::from_array(Array::make(256, '0'))
  let out = @metrology.explain(
    measurement(),
    quartet(),
    Some({ ..budget(), offset_limit_scaled: oversized, }),
  )
  assert_eq(out.status.label(), "Violation")
}

///|
test "PTP quartet missing duplicate and wrong identity cannot create ledger" {
  let fs = quartet()
  let missing = @metrology.explain(measurement(), fs[:3].to_owned(), None)
  assert_eq(missing.status.label(), "InsufficientEvidence")
  let duplicate = fs.copy()
  duplicate.push(fs[0])
  assert_eq(
    @metrology.explain(measurement(), duplicate, None).status.label(),
    "InsufficientEvidence",
  )
  fs[3] = {
    ..fs[3],
    packet: {
      ..fs[3].packet,
      header: { ..fs[3].packet.header, sequence: 21, },
    },
  }
  assert_eq(
    @metrology.explain(measurement(), fs, None).status.label(),
    "Violation",
  )
  assert_eq(
    @metrology.explain(
      { ..measurement(), frames: [1, 2, 3, 3], },
      quartet(),
      None,
    ).status.label(),
    "Violation",
  )
}

///|
test "PTP shared epoch and timestamp provenance remain required" {
  let fs = quartet()
  fs[2] = { ..fs[2], epoch: Some(10), }
  assert_eq(
    @metrology.explain(measurement(), fs, None).status.label(),
    "InsufficientEvidence",
  )
  fs[2] = { ..fs[2], epoch: Some(9), direction: Some("rx"), }
  assert_eq(
    @metrology.explain(measurement(), fs, None).status.label(),
    "InsufficientEvidence",
  )
  fs[2] = { ..fs[2], direction: Some("tx"), event_time: None, }
  assert_eq(
    @metrology.explain(measurement(), fs, None).status.label(),
    "InsufficientEvidence",
  )
}

///|
test "PTP supplied measurement values must match reconstructed operands" {
  let inconsistent = @metrology.explain(
    { ..measurement(), offset_numerator: "98305", },
    quartet(),
    None,
  )
  assert_eq(inconsistent.status.label(), "Violation")
  assert_true(inconsistent.ledger is None)
  assert_eq(
    @metrology.explain(
      { ..measurement(), forward_scaled: "019628032", },
      quartet(),
      None,
    ).status.label(),
    "Violation",
  )
  assert_eq(
    @metrology.explain(
      { ..measurement(), denominator: 65536, },
      quartet(),
      None,
    ).status.label(),
    "Violation",
  )
}

///|
test "PTP explanation JSON distinguishes algebra Pass from conditional limit verdict" {
  let out = @metrology.explain(
    measurement(),
    quartet(),
    Some({ ..budget(), offset_limit_scaled: "0", }),
  )
  assert_eq(out.status.label(), "Pass")
  assert_eq(out.assessment.unwrap().verdict, "outside_limit")
  assert_true(
    out.to_json()
    is {
      "status": String("Pass"),
      "assessment": { "verdict": String("outside_limit"), .. },
      ..
    },
  )
  assert_true(
    @metrology.explain(measurement(), quartet(), None).to_json()
    is { "assessment": Null, "assessment_state": String("not_assessed"), .. },
  )
}
