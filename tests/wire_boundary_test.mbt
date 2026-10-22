// Generated independent struct wire boundary vectors.

///|
test "wire independent Int64 vector 0" {
  let bytes = match
    @wire.from_hex(
      "0802002c00000000800000000000000000000000001122334455667700010000028000000000000000000000",
    ) {
    Ok(v) => v
    Err(_) => panic()
  }
  let p = match @wire.decode(bytes) {
    Ok(v) => v
    Err(_) => panic()
  }
  assert_eq(p.header.correction, -9223372036854775807L - 1L)
  assert_eq(p.header.sequence, 0)
  assert_eq(p.header.log_interval, -128)
  assert_eq(p.header.source.clock, "0011223344556677")
  match p.body {
    @wire.TimestampBody(t) => {
      assert_eq(t.seconds, 0L)
      assert_eq(t.nanos, 0)
    }
    _ => assert_true(false)
  }
  assert_eq(
    @wire.to_hex(
      match @wire.encode(p) {
        Ok(v) => v
        Err(_) => panic()
      },
    ),
    "0802002c00000000800000000000000000000000001122334455667700010000028000000000000000000000",
  )
}

///|
test "wire independent Int64 vector 1" {
  let bytes = match
    @wire.from_hex(
      "0802002c000000007ffffffffffffffe0000000000112233445566770001ffff027fffffffffffff3b9ac9ff",
    ) {
    Ok(v) => v
    Err(_) => panic()
  }
  let p = match @wire.decode(bytes) {
    Ok(v) => v
    Err(_) => panic()
  }
  assert_eq(p.header.correction, 9223372036854775806L)
  assert_eq(p.header.sequence, 65535)
  assert_eq(p.header.log_interval, 127)
  assert_eq(p.header.source.clock, "0011223344556677")
  match p.body {
    @wire.TimestampBody(t) => {
      assert_eq(t.seconds, 281474976710655L)
      assert_eq(t.nanos, 999999999)
    }
    _ => assert_true(false)
  }
  assert_eq(
    @wire.to_hex(
      match @wire.encode(p) {
        Ok(v) => v
        Err(_) => panic()
      },
    ),
    "0802002c000000007ffffffffffffffe0000000000112233445566770001ffff027fffffffffffff3b9ac9ff",
  )
}

///|
test "wire independent Int64 vector 2" {
  let bytes = match
    @wire.from_hex(
      "0802002c00000000fffffffffffffffe0000000000112233445566770001800002ff00000000000100000001",
    ) {
    Ok(v) => v
    Err(_) => panic()
  }
  let p = match @wire.decode(bytes) {
    Ok(v) => v
    Err(_) => panic()
  }
  assert_eq(p.header.correction, -2L)
  assert_eq(p.header.sequence, 32768)
  assert_eq(p.header.log_interval, -1)
  assert_eq(p.header.source.clock, "0011223344556677")
  match p.body {
    @wire.TimestampBody(t) => {
      assert_eq(t.seconds, 1L)
      assert_eq(t.nanos, 1)
    }
    _ => assert_true(false)
  }
  assert_eq(
    @wire.to_hex(
      match @wire.encode(p) {
        Ok(v) => v
        Err(_) => panic()
      },
    ),
    "0802002c00000000fffffffffffffffe0000000000112233445566770001800002ff00000000000100000001",
  )
}

///|
test "wire independent Int64 vector 3" {
  let bytes = match
    @wire.from_hex(
      "0802002c0000000000000000000000010000000000112233445566770001000102000000000000003b9ac9ff",
    ) {
    Ok(v) => v
    Err(_) => panic()
  }
  let p = match @wire.decode(bytes) {
    Ok(v) => v
    Err(_) => panic()
  }
  assert_eq(p.header.correction, 1L)
  assert_eq(p.header.sequence, 1)
  assert_eq(p.header.log_interval, 0)
  assert_eq(p.header.source.clock, "0011223344556677")
  match p.body {
    @wire.TimestampBody(t) => {
      assert_eq(t.seconds, 0L)
      assert_eq(t.nanos, 999999999)
    }
    _ => assert_true(false)
  }
  assert_eq(
    @wire.to_hex(
      match @wire.encode(p) {
        Ok(v) => v
        Err(_) => panic()
      },
    ),
    "0802002c0000000000000000000000010000000000112233445566770001000102000000000000003b9ac9ff",
  )
}
