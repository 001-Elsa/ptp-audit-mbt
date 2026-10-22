///|
test "scope rejects malformed input" {
  let r = @audit.audit("{}")
  assert_eq(r.status().label(), "Violation")
  assert_eq(r.exit_code(), 1)
}

///|
test "wire round trip preserves negative correction" {
  let p : @wire.Packet = {
    header: {
      kind: @wire.Sync,
      domain: 0,
      flags: 0x0200,
      correction: -65536L,
      source: { clock: "00000000000000aa", port: 1, },
      sequence: 7,
      log_interval: 0,
    },
    body: @wire.TimestampBody({ seconds: 100L, nanos: 123, }),
  }
  let b = match @wire.encode(p) {
    Ok(x) => x
    Err(_) => {
      assert_true(false)
      panic()
    }
  }
  let q = match @wire.decode(b) {
    Ok(x) => x
    Err(_) => {
      assert_true(false)
      panic()
    }
  }
  assert_eq(
    @wire.to_hex(b),
    @wire.to_hex(
      match @wire.encode(q) {
        Ok(x) => x
        Err(_) => panic()
      },
    ),
  )
}

///|
fn dataset(gm : String, p : Int32) -> @wire.AnnounceData {
  {
    origin: { seconds: 0L, nanos: 0, },
    utc_offset: 0,
    priority1: p,
    clock_class: 1,
    accuracy: 1,
    variance: 1,
    priority2: 1,
    grandmaster: gm,
    steps_removed: 0,
    time_source: 0,
  }
}

///|
test "bmca prefers lower priority" {
  let a : @bmca.Candidate = {
    id: "a",
    frame: 1,
    domain: 0,
    data: dataset("0000000000000001", 10),
    sender: { clock: "0000000000000001", port: 1, },
    receiver: { clock: "00000000000000aa", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "b",
    frame: 2,
    domain: 0,
    data: dataset("0000000000000002", 20),
    sender: { clock: "0000000000000002", port: 1, },
    receiver: { clock: "00000000000000aa", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.rule, "BMCA.DIFFERENT_GM.priority1")
}
