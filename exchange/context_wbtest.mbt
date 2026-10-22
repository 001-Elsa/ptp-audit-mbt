///|
fn lifecycle_test_context(
  complete : Bool,
  end_nanos : Int32,
) -> @observation.Context {
  {
    windows: [
      {
        id: "capture-a",
        epoch: 9,
        clock_domain: "capture-clock",
        start: { seconds: 100L, nanos: 0, },
        end: { seconds: 100L, nanos: end_nanos, },
        complete,
      },
    ],
    policy: Some({
      source: "commissioning profile lifecycle test",
      sync_follow_up_ns: Some(100L),
      delay_response_ns: Some(200L),
    }),
  }
}

///|
fn lifecycle_test_frame(
  id : Int32,
  kind : @wire.Kind,
  captured_ns : Int32,
) -> Frame {
  let master : @wire.PortIdentity = { clock: "000000000000000a", port: 1, }
  let slave : @wire.PortIdentity = { clock: "000000000000000b", port: 2, }
  let time : @wire.PtpTimestamp = { seconds: 100L, nanos: captured_ns, }
  {
    id,
    epoch: Some(9),
    window: Some("capture-a"),
    capture_time: Some(time),
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
        correction: 0L,
        source: if kind == @wire.DelayReq {
          slave
        } else {
          master
        },
        sequence: if kind == @wire.DelayReq || kind == @wire.DelayResp {
          20
        } else {
          10
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
}

///|
fn lifecycle_test_claim() -> ExchangeClaim {
  { sync: 1, follow_up: 2, delay_req: 3, delay_resp: 4, }
}

///|
test "lifecycle consumes timely sync pair independently of input arrival order" {
  let sync = lifecycle_test_frame(1, @wire.Sync, 20)
  let follow_up = lifecycle_test_frame(2, @wire.FollowUp, 100)
  assert_eq(
    lifecycle_findings(
      [follow_up, sync],
      [],
      lifecycle_test_context(true, 1000),
    ).length(),
    0,
  )
}

///|
test "lifecycle accepts follow up captured before sync at exact budget boundary" {
  assert_eq(
    lifecycle_findings(
      [
        lifecycle_test_frame(1, @wire.Sync, 150),
        lifecycle_test_frame(2, @wire.FollowUp, 50),
      ],
      [],
      lifecycle_test_context(true, 1000),
    ).length(),
    0,
  )
}

///|
test "lifecycle does not add evidence gaps to complete explicit exchange" {
  let findings = lifecycle_findings(
    [
      lifecycle_test_frame(4, @wire.DelayResp, 250),
      lifecycle_test_frame(2, @wire.FollowUp, 100),
      lifecycle_test_frame(3, @wire.DelayReq, 200),
      lifecycle_test_frame(1, @wire.Sync, 20),
    ],
    [lifecycle_test_claim()],
    lifecycle_test_context(true, 1000),
  )
  assert_eq(findings.length(), 0)
}

///|
test "lifecycle evicts late same key counterpart before matching" {
  let findings = lifecycle_findings(
    [
      lifecycle_test_frame(1, @wire.Sync, 0),
      lifecycle_test_frame(2, @wire.FollowUp, 101),
    ],
    [],
    lifecycle_test_context(true, 1000),
  )
  assert_eq(findings.length(), 2)
  assert_true(
    findings.all(fn(finding) {
      finding.rule == "EXCHANGE.STATE.EVICTED" &&
      finding.status == @diagnostic.InsufficientEvidence
    }),
  )
  assert_eq(findings[0].frames[0], 1)
}

///|
test "lifecycle duplicate sync keys never consume a unique follow up" {
  let findings = lifecycle_findings(
    [
      lifecycle_test_frame(1, @wire.Sync, 10),
      lifecycle_test_frame(8, @wire.Sync, 20),
      lifecycle_test_frame(2, @wire.FollowUp, 30),
    ],
    [],
    lifecycle_test_context(true, 1000),
  )
  assert_eq(findings.length(), 3)
  assert_true(
    findings.all(fn(finding) { finding.rule == "EXCHANGE.STATE.EVICTED" }),
  )
}

///|
test "lifecycle duplicate response keys never consume a unique request" {
  let findings = lifecycle_findings(
    [
      lifecycle_test_frame(1, @wire.Sync, 10),
      lifecycle_test_frame(2, @wire.FollowUp, 20),
      lifecycle_test_frame(3, @wire.DelayReq, 30),
      lifecycle_test_frame(4, @wire.DelayResp, 40),
      lifecycle_test_frame(5, @wire.DelayResp, 50),
    ],
    [lifecycle_test_claim()],
    lifecycle_test_context(true, 1000),
  )
  assert_eq(findings.length(), 3)
  assert_true(
    findings.all(fn(finding) { finding.rule == "EXCHANGE.STATE.EVICTED" }),
  )
}

///|
test "lifecycle cannot infer intended delay master without explicit association" {
  let findings = lifecycle_findings(
    [
      lifecycle_test_frame(3, @wire.DelayReq, 100),
      lifecycle_test_frame(4, @wire.DelayResp, 150),
    ],
    [],
    lifecycle_test_context(true, 1000),
  )
  assert_eq(findings.length(), 2)
  assert_true(
    findings.all(fn(finding) { finding.rule == "EXCHANGE.STATE.EVICTED" }),
  )
}

///|
test "lifecycle rejects wrong master response even when request identity agrees" {
  let wrong = lifecycle_test_frame(4, @wire.DelayResp, 150)
  let wrong_master : Frame = {
    ..wrong,
    packet: {
      ..wrong.packet,
      header: {
        ..wrong.packet.header,
        source: { clock: "000000000000000c", port: 1, },
      },
    },
  }
  let findings = lifecycle_findings(
    [
      lifecycle_test_frame(1, @wire.Sync, 10),
      lifecycle_test_frame(2, @wire.FollowUp, 20),
      lifecycle_test_frame(3, @wire.DelayReq, 100),
      wrong_master,
    ],
    [lifecycle_test_claim()],
    lifecycle_test_context(true, 1000),
  )
  assert_eq(findings.length(), 2)
  assert_true(
    findings.all(fn(finding) { finding.rule == "EXCHANGE.STATE.EVICTED" }),
  )
}

///|
test "lifecycle window end before deadline leaves pending state" {
  let findings = lifecycle_findings(
    [lifecycle_test_frame(1, @wire.Sync, 100)],
    [],
    lifecycle_test_context(true, 199),
  )
  assert_eq(findings.length(), 1)
  assert_eq(findings[0].rule, "EXCHANGE.STATE.PENDING")
  assert_true(findings[0].status == @diagnostic.InsufficientEvidence)
}

///|
test "lifecycle complete window deadline boundary evicts pending state" {
  let findings = lifecycle_findings(
    [lifecycle_test_frame(1, @wire.Sync, 100)],
    [],
    lifecycle_test_context(true, 200),
  )
  assert_eq(findings.length(), 1)
  assert_eq(findings[0].rule, "EXCHANGE.STATE.EVICTED")
}

///|
test "lifecycle incomplete window does not turn input end into expiry" {
  let findings = lifecycle_findings(
    [lifecycle_test_frame(1, @wire.Sync, 100)],
    [],
    lifecycle_test_context(false, 1000),
  )
  assert_eq(findings.length(), 1)
  assert_eq(findings[0].rule, "EXCHANGE.STATE.PENDING")
}

///|
test "lifecycle independent epoch partitions do not match or advance deadlines" {
  let first_window = lifecycle_test_context(true, 100).windows[0]
  let ctx : @observation.Context = {
    windows: [
      first_window,
      {
        ..first_window,
        id: "capture-b",
        epoch: 10,
        end: { seconds: 100L, nanos: 1000, },
      },
    ],
    policy: lifecycle_test_context(true, 1000).policy,
  }
  let follow_up = lifecycle_test_frame(2, @wire.FollowUp, 1000)
  let findings = lifecycle_findings(
    [
      lifecycle_test_frame(1, @wire.Sync, 50),
      { ..follow_up, epoch: Some(10), window: Some("capture-b"), },
    ],
    [],
    ctx,
  )
  assert_eq(findings.length(), 2)
  assert_true(
    findings.all(fn(finding) { finding.rule == "EXCHANGE.STATE.PENDING" }),
  )
}

///|
test "lifecycle missing capture metadata never creates a pending association" {
  let original = lifecycle_test_frame(1, @wire.Sync, 10)
  for
    frame in [
      { ..original, epoch: None, },
      { ..original, window: None, },
      { ..original, capture_time: None, },
      { ..original, capture_clock_domain: None, },
    ] {
    let findings = lifecycle_findings(
      [frame],
      [],
      lifecycle_test_context(true, 1000),
    )
    assert_true(findings.length() > 0)
    assert_true(
      findings.all(fn(finding) {
        finding.status == @diagnostic.InsufficientEvidence &&
        finding.rule != "EXCHANGE.STATE.EVICTED"
      }),
    )
  }
}

///|
test "lifecycle actual expiry releases state before a later unrelated event" {
  let unrelated = lifecycle_test_frame(8, @wire.Sync, 200)
  let findings = lifecycle_findings(
    [
      lifecycle_test_frame(1, @wire.Sync, 0),
      {
        ..unrelated,
        packet: {
          ..unrelated.packet,
          header: { ..unrelated.packet.header, sequence: 11, },
        },
      },
      lifecycle_test_frame(2, @wire.FollowUp, 250),
    ],
    [],
    lifecycle_test_context(true, 1000),
  )
  assert_eq(findings.length(), 3)
  assert_eq(findings[0].frames[0], 1)
  assert_eq(findings[0].rule, "EXCHANGE.STATE.EVICTED")
}

///|
test "lifecycle exact maximum timestamp arithmetic does not overflow" {
  let ctx = lifecycle_test_context(true, 1000)
  ctx.windows[0] = {
    ..ctx.windows[0],
    start: { seconds: 281474976710655L, nanos: 0, },
    end: { seconds: 281474976710655L, nanos: 999999999, },
  }
  let original = lifecycle_test_frame(1, @wire.Sync, 0)
  let findings = lifecycle_findings(
    [
      {
        ..original,
        capture_time: Some({ seconds: 281474976710655L, nanos: 999999999, }),
      },
    ],
    [],
    ctx,
  )
  assert_eq(findings.length(), 1)
  assert_eq(findings[0].rule, "EXCHANGE.STATE.PENDING")
}
