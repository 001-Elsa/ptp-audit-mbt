// Negative tests use literal on-wire bytes or deliberately invalid public API
// values. They assert the rule, severity and evidence location, rather than
// reproducing the implementation predicate. Observation/resource rules are
// project policies; these tests do not certify IEEE conformance.

///|
fn coverage_hex(text : String) -> Bytes {
  match @wire.from_hex(text) {
    Ok(value) => value
    Err(_) => panic()
  }
}

///|
fn coverage_wire_error(
  result : Result[@wire.Packet, @wire.WireError],
  rule : String,
  status : @diagnostic.Status,
  offset : Int32,
) -> Unit raise {
  match result {
    Ok(_) => fail("invalid/unsupported bytes unexpectedly decoded")
    Err(error) => {
      assert_eq(error.code, rule)
      assert_eq(error.status.label(), status.label())
      assert_eq(error.offset, offset)
      assert_true(error.expected.length() > 0 && error.actual.length() > 0)
    }
  }
}

///|
fn coverage_encode_error(
  packet : @wire.Packet,
  rule : String,
  offset : Int32,
) -> Unit raise {
  match @wire.encode(packet) {
    Ok(_) => fail("invalid typed value unexpectedly encoded")
    Err(error) => {
      assert_eq(error.code, rule)
      assert_eq(error.status.label(), "Violation")
      assert_eq(error.offset, offset)
    }
  }
}

///|
fn coverage_packet() -> @wire.Packet {
  {
    header: {
      kind: @wire.FollowUp,
      domain: 0,
      flags: 0,
      correction: 0L,
      source: { clock: "0011223344556677", port: 1, },
      sequence: 7,
      log_interval: 0,
    },
    body: @wire.TimestampBody({ seconds: 100L, nanos: 200, }),
  }
}

///|
fn coverage_announce() -> @wire.AnnounceData {
  {
    origin: { seconds: 0L, nanos: 0, },
    utc_offset: 37,
    priority1: 128,
    clock_class: 248,
    accuracy: 254,
    variance: 65535,
    priority2: 128,
    grandmaster: "0011223344556677",
    steps_removed: 1,
    time_source: 160,
  }
}

///|
fn coverage_findings(
  findings : Array[@diagnostic.Finding],
  rule : String,
  status : @diagnostic.Status,
) -> Unit raise {
  let matching = findings.filter(fn(finding) { finding.rule == rule })
  assert_eq(matching.length(), 1)
  assert_eq(matching[0].status.label(), status.label())
}

///|
fn coverage_context() -> @observation.Context {
  {
    windows: [
      {
        id: "coverage-window",
        epoch: 4,
        clock_domain: "capture-clock",
        start: { seconds: 100L, nanos: 0, },
        end: { seconds: 100L, nanos: 10000, },
        complete: true,
      },
    ],
    policy: Some({
      source: "explicit negative-test analysis policy",
      sync_follow_up_ns: Some(1000L),
      delay_response_ns: Some(1000L),
    }),
  }
}

///|
fn coverage_frame() -> @exchange.Frame {
  {
    id: 1,
    epoch: Some(4),
    window: Some("coverage-window"),
    capture_time: Some({ seconds: 100L, nanos: 100, }),
    capture_clock_domain: Some("capture-clock"),
    packet: coverage_packet(),
    local_port: Some({ clock: "8899aabbccddeeff", port: 1, }),
    event_time: Some({ seconds: 100L, nanos: 100, }),
    clock_domain: Some("event-clock"),
    direction: Some("rx"),
  }
}

///|
fn coverage_exchange(frames : Array[@exchange.Frame]) -> @exchange.Report {
  @exchange.audit(frames, [], [], true, true, true, coverage_context())
}

///|
fn coverage_candidate(
  id : String,
  frame : Int32,
  gm : String,
  priority : Int32,
  steps : Int32,
) -> @bmca.Candidate {
  {
    id,
    frame,
    domain: 0,
    data: {
      ..coverage_announce(),
      grandmaster: gm,
      priority1: priority,
      steps_removed: steps,
    },
    sender: { clock: "0011223344556677", port: 1, },
    receiver: { clock: "8899aabbccddeeff", port: 1, },
  }
}

///|
fn coverage_bmca(
  candidates : Array[@bmca.Candidate],
) -> Array[@diagnostic.Finding] {
  @bmca.audit(candidates, Some("c"), true, true, coverage_context(), {
    epoch: Some(4),
    window: Some("coverage-window"),
    clock_domain: Some("capture-clock"),
    decision_time: Some({ seconds: 100L, nanos: 200, }),
    announce_validity_ns: Some(1000L),
    validity_source: Some("explicit test snapshot policy"),
    validity_confirmed: true,
    capture_window_confirmed: true,
    samples: candidates.map(fn(candidate) {
      @observation.Sample::{
        frame: candidate.frame,
        epoch: Some(4),
        window: Some("coverage-window"),
        time: Some({ seconds: 100L, nanos: 100, }),
        clock_domain: Some("capture-clock"),
      }
    }),
  })
}

///|
test "rule coverage WIRE.HEADER_LENGTH rejects every short common header" {
  // Every possible truncated common-header length is checked before indexing.
  for length = 0; length < 34; length = length + 1 {
    coverage_wire_error(
      @wire.decode(Bytes::from_array(Array::make(length, b'\x00'))),
      "WIRE.HEADER_LENGTH",
      @diagnostic.Violation,
      0,
    )
  }
}

///|
test "rule coverage WIRE.BODY_LENGTH distinguishes self-consistent truncation" {
  // Each length field matches actual bytes, isolating body length from the
  // independent WIRE.MESSAGE_LENGTH check. Type, control and body are literal.
  for
    text in [
      "00020022000002000000000000000000000000000011223344556677000100070000", "01020022000000000000000000000000000000000011223344556677000100070100",
      "08020022000000000000000000000000000000000011223344556677000100070200", "09020022000000000000000000000000000000000011223344556677000100070300",
      "0b020022000000000000000000000000000000000011223344556677000100070500",
    ] {
    coverage_wire_error(
      @wire.decode(coverage_hex(text)),
      "WIRE.BODY_LENGTH",
      @diagnostic.Violation,
      2,
    )
  }
}

///|
test "rule coverage WIRE.REQUESTER_PORT rejects zero response requester" {
  coverage_wire_error(
    @wire.decode(
      coverage_hex(
        "09020036000000000000000000000000000000000011223344556677000100070300000000000064000000c88899aabbccddeeff0000",
      ),
    ),
    "WIRE.REQUESTER_PORT",
    @diagnostic.Violation,
    52,
  )
}

///|
test "rule coverage SCOPE.VERSION excludes later or reserved version octets" {
  for version in [b'\x01', b'\x03', b'\x12'] {
    let bytes = coverage_hex(
      "0802002c000000000000000000000000000000000011223344556677000100070200000000000064000000c8",
    ).to_array()
    bytes[1] = version
    coverage_wire_error(
      @wire.decode(Bytes::from_array(bytes)),
      "SCOPE.VERSION",
      @diagnostic.Unsupported,
      1,
    )
  }
}

///|
test "rule coverage SCOPE.PROFILE excludes each nonzero transportSpecific nibble" {
  for profile = 1; profile <= 15; profile = profile + 1 {
    let bytes = coverage_hex(
      "0802002c000000000000000000000000000000000011223344556677000100070200000000000064000000c8",
    ).to_array()
    bytes[0] = ((profile << 4) | 8).to_byte()
    coverage_wire_error(
      @wire.decode(Bytes::from_array(bytes)),
      "SCOPE.PROFILE",
      @diagnostic.Unsupported,
      0,
    )
  }
}

///|
test "rule coverage SCOPE.MESSAGE excludes every unsupported message type" {
  for kind in [2, 3, 4, 5, 6, 7, 10, 12, 13, 14, 15] {
    let bytes = coverage_hex(
      "0802002c000000000000000000000000000000000011223344556677000100070200000000000064000000c8",
    ).to_array()
    bytes[0] = kind.to_byte()
    coverage_wire_error(
      @wire.decode(Bytes::from_array(bytes)),
      "SCOPE.MESSAGE",
      @diagnostic.Unsupported,
      0,
    )
  }
}

///|
test "rule coverage SCOPE.FLAGS excludes every unsupported flag bit separately" {
  for flag in [0x0040, 0x0080, 0x0800, 0x1000, 0x2000, 0x4000, 0x8000] {
    let bytes = coverage_hex(
      "0802002c000000000000000000000000000000000011223344556677000100070200000000000064000000c8",
    ).to_array()
    bytes[6] = (flag >> 8).to_byte()
    bytes[7] = (flag & 255).to_byte()
    coverage_wire_error(
      @wire.decode(Bytes::from_array(bytes)),
      "SCOPE.FLAGS",
      @diagnostic.Unsupported,
      6,
    )
  }
}

///|
test "rule coverage SCOPE.MODE excludes alternate-master and unicast independently" {
  for flag in [0x0100, 0x0400] {
    let bytes = coverage_hex(
      "0802002c000000000000000000000000000000000011223344556677000100070200000000000064000000c8",
    ).to_array()
    bytes[6] = (flag >> 8).to_byte()
    coverage_wire_error(
      @wire.decode(Bytes::from_array(bytes)),
      "SCOPE.MODE",
      @diagnostic.Unsupported,
      6,
    )
  }
}

///|
test "rule coverage WIRE.FIELD_RANGE rejects lossy header encodings" {
  let good = coverage_packet()
  let h = good.header
  for
    header in [
      { ..h, domain: -1, },
      { ..h, domain: 256, },
      { ..h, sequence: -1, },
      { ..h, sequence: 65536, },
      { ..h, flags: -1, },
      { ..h, flags: 65536, },
      { ..h, log_interval: -129, },
      { ..h, log_interval: 128, },
      { ..h, source: { clock: "0011223344556677", port: 0, }, },
      { ..h, source: { clock: "0011223344556677", port: 65536, }, },
      { ..h, source: { clock: "00112233445566", port: 1, }, },
      { ..h, source: { clock: "00112233445566gg", port: 1, }, },
      { ..h, source: { clock: "00112233445566AA", port: 1, }, },
    ] {
    coverage_encode_error({ ..good, header, }, "WIRE.FIELD_RANGE", 0)
  }
}

///|
test "rule coverage WIRE.TIMESTAMP rejects each out-of-range component" {
  let good = coverage_packet()
  for
    time in [
      @wire.PtpTimestamp::{ seconds: -1L, nanos: 0, },
      { seconds: 281474976710656L, nanos: 0, },
      { seconds: 0L, nanos: -1, },
      { seconds: 0L, nanos: 1000000000, },
    ] {
    coverage_encode_error(
      { ..good, body: @wire.TimestampBody(time), },
      "WIRE.TIMESTAMP",
      34,
    )
  }
}

///|
test "rule coverage WIRE.BODY_KIND rejects mismatched typed body variants" {
  let good = coverage_packet()
  let time : @wire.PtpTimestamp = { seconds: 100L, nanos: 200, }
  let port : @wire.PortIdentity = { clock: "8899aabbccddeeff", port: 1, }
  for
    (kind, body) in [
      (@wire.Sync, @wire.Response(time, port)),
      (@wire.FollowUp, @wire.Announcement(coverage_announce())),
      (@wire.DelayReq, @wire.Response(time, port)),
      (@wire.DelayResp, @wire.TimestampBody(time)),
      (@wire.Announce, @wire.TimestampBody(time)),
    ] {
    coverage_encode_error(
      { header: { ..good.header, kind, }, body, },
      "WIRE.BODY_KIND",
      34,
    )
  }
}

///|
test "rule coverage WIRE.RESPONSE rejects invalid requester and timestamp" {
  let good = coverage_packet()
  let header = { ..good.header, kind: @wire.DelayResp, }
  let time : @wire.PtpTimestamp = { seconds: 100L, nanos: 200, }
  let port : @wire.PortIdentity = { clock: "8899aabbccddeeff", port: 1, }
  for
    (t, p) in [
      (time, { ..port, port: 0, }),
      (time, { ..port, clock: "8899aabbccddeefg", }),
      ({ ..time, nanos: 1000000000, }, port),
      ({ ..time, seconds: -1L, }, port),
    ] {
    coverage_encode_error(
      { header, body: @wire.Response(t, p), },
      "WIRE.RESPONSE",
      34,
    )
  }
}

///|
test "rule coverage WIRE.ANNOUNCE rejects each lossy field" {
  let good = coverage_packet()
  let header = { ..good.header, kind: @wire.Announce, }
  let a = coverage_announce()
  for
    data in [
      { ..a, origin: { seconds: -1L, nanos: 0, }, },
      { ..a, utc_offset: -32769, },
      { ..a, utc_offset: 32768, },
      { ..a, priority1: -1, },
      { ..a, priority1: 256, },
      { ..a, clock_class: -1, },
      { ..a, clock_class: 256, },
      { ..a, accuracy: -1, },
      { ..a, accuracy: 256, },
      { ..a, variance: -1, },
      { ..a, variance: 65536, },
      { ..a, priority2: -1, },
      { ..a, priority2: 256, },
      { ..a, grandmaster: "00112233445566zz", },
      { ..a, steps_removed: -1, },
      { ..a, steps_removed: 65536, },
      { ..a, time_source: -1, },
      { ..a, time_source: 256, },
    ] {
    coverage_encode_error(
      { header, body: @wire.Announcement(data), },
      "WIRE.ANNOUNCE",
      34,
    )
  }
}

///|
test "rule coverage EXCHANGE.RESOURCE rejects excess frames and both claim lists" {
  let frame = coverage_frame()
  let excessive = 257
  for
    report in [
      coverage_exchange(Array::make(excessive, frame)),
      @exchange.audit(
        [],
        Array::make(excessive, @exchange.PairClaim::{ sync: 1, follow_up: 2, }),
        [],
        true,
        true,
        true,
        coverage_context(),
      ),
      @exchange.audit(
        [],
        [],
        Array::make(excessive, @exchange.ExchangeClaim::{
          sync: 1,
          follow_up: 2,
          delay_req: 3,
          delay_resp: 4,
        }),
        true,
        true,
        true,
        coverage_context(),
      ),
    ] {
    coverage_findings(
      report.findings,
      "EXCHANGE.RESOURCE",
      @diagnostic.Unsupported,
    )
    assert_eq(report.findings.length(), 1)
    assert_eq(report.measurements.length(), 0)
  }
}

///|
test "rule coverage INPUT.FRAME_ID rejects ambiguous typed frame identity" {
  let f = coverage_frame()
  let report = coverage_exchange([f, f])
  coverage_findings(report.findings, "INPUT.FRAME_ID", @diagnostic.Violation)
  assert_eq(report.measurements.length(), 0)
  assert_eq(report.findings[0].frames, [1])
}

///|
test "rule coverage INPUT.FRAME_METADATA rejects invalid typed observation fields" {
  let f = coverage_frame()
  for
    invalid in [
      { ..f, id: -1, },
      { ..f, epoch: Some(-1), },
      { ..f, event_time: Some({ seconds: 100L, nanos: 1000000000, }), },
      { ..f, local_port: Some({ clock: "8899aabbccddeeff", port: 0, }), },
      { ..f, direction: Some("RX"), },
      { ..f, direction: Some(""), },
    ] {
    let report = coverage_exchange([invalid])
    coverage_findings(
      report.findings,
      "INPUT.FRAME_METADATA",
      @diagnostic.Violation,
    )
    assert_eq(report.measurements.length(), 0)
    assert_eq(report.findings[0].frames, [invalid.id])
  }
}

///|
test "rule coverage INPUT.RESOURCE enforces the UTF-16 input boundary" {
  // Equal-to-limit text reaches JSON validation; one extra code unit is
  // rejected as a resource limit, independently of JSON validity.
  let at_limit = @audit.audit(String::make(1048576, ' '))
  coverage_findings(at_limit.findings, "INPUT.SCHEMA", @diagnostic.Violation)
  let above_limit = @audit.audit(String::make(1048577, ' '))
  coverage_findings(
    above_limit.findings,
    "INPUT.RESOURCE",
    @diagnostic.Unsupported,
  )
  assert_eq(above_limit.measurements.length(), 0)
  assert_eq(above_limit.findings[0].actual, "1048577")
}

///|
test "rule coverage OBSERVATION.RESOURCE rejects excess windows without lookup" {
  let context = coverage_context()
  let excessive = { ..context, windows: Array::make(65, context.windows[0]), }
  let findings = @observation.validate(excessive)
  coverage_findings(findings, "OBSERVATION.RESOURCE", @diagnostic.Unsupported)
  assert_eq(findings.length(), 1)
  assert_true(@observation.get_window(excessive, "coverage-window") is None)
}

///|
test "rule coverage BMCA.RESOURCE rejects excess qualified candidates" {
  let c = coverage_candidate("c", 1, "0011223344556677", 10, 1)
  let findings = coverage_bmca(Array::make(65, c))
  coverage_findings(findings, "BMCA.RESOURCE", @diagnostic.Unsupported)
  assert_eq(findings.length(), 1)
}

///|
test "rule coverage BMCA.CANDIDATE_UNIQUENESS rejects duplicate ids or frames" {
  let a = coverage_candidate("a", 1, "0011223344556677", 10, 1)
  let b = coverage_candidate("b", 2, "0011223344556688", 20, 1)
  for candidates in [[a, { ..b, id: "a", }], [a, { ..b, frame: 1, }]] {
    // Explicit caller incompleteness bypasses freshness, while preserving
    // validation of public candidate identities before any preference claim.
    let findings = @bmca.audit(
      candidates,
      None,
      false,
      true,
      coverage_context(),
      {
        epoch: None,
        window: None,
        clock_domain: None,
        decision_time: None,
        announce_validity_ns: None,
        validity_source: None,
        validity_confirmed: false,
        capture_window_confirmed: false,
        samples: [],
      },
    )
    coverage_findings(
      findings,
      "BMCA.CANDIDATE_UNIQUENESS",
      @diagnostic.Violation,
    )
    assert_eq(findings.length(), 1)
  }
}

///|
test "rule coverage BMCA.SCOPE.NO_UNIVERSAL_WINNER blocks cyclic supplied datasets" {
  // Same-GM priority fields can be inconsistent in caller-supplied input.
  // A beats B by priority, B beats C by priority, C beats A by same-GM steps.
  // The auditor must not promote the fold's provisional C to a valid winner.
  let a = coverage_candidate("a", 1, "0011223344556677", 10, 1)
  let b = coverage_candidate("b", 2, "0011223344556688", 20, 0)
  let c = coverage_candidate("c", 3, "0011223344556677", 30, 0)
  assert_eq(@bmca.compare(a, b).side, -1)
  assert_eq(@bmca.compare(b, c).side, -1)
  assert_eq(@bmca.compare(c, a).side, -1)
  let findings = coverage_bmca([a, b, c])
  coverage_findings(
    findings,
    "BMCA.SCOPE.NO_UNIVERSAL_WINNER",
    @diagnostic.Unsupported,
  )
  assert_eq(
    findings.filter(fn(f) { f.rule == "BMCA.OBSERVED_DECISION" }).length(),
    0,
  )
}
