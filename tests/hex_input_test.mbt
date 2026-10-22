// Public input behavior remains stable when delegating hexadecimal decoding
// to the standard library. Positions refer to payload octets, not UTF-8 bytes.

///|
test "hex accepts empty mixed case and the maximum bounded payload" {
  assert_true(@wire.from_hex("") is Ok(b""))
  assert_true(@wire.from_hex("aB01fF") is Ok(b"\xab\x01\xff"))
  let boundary = String::make(4096, '0')
  match @wire.from_hex(boundary) {
    Ok(bytes) => assert_eq(bytes.length(), 2048)
    Err(_) => fail("maximum bounded input rejected")
  }
}

///|
test "hex rejects malformed input with its first payload octet location" {
  for
    (text, octet) in [("0011z2", 2), ("0Z11", 0), ("0011😀", 2), ("00é0", 1)] {
    match @wire.from_hex(text) {
      Err(error) => {
        assert_eq(error.code, "WIRE.HEX")
        assert_eq(error.offset, octet)
        assert_eq(error.expected, "hex octet")
        assert_eq(error.actual, "non-hex character")
      }
      Ok(_) => fail("non-hex input accepted")
    }
  }
}

///|
test "hex length gate takes precedence over character validation" {
  for text in ["z", String::make(4098, 'z')] {
    match @wire.from_hex(text) {
      Err(error) => {
        assert_eq(error.code, "WIRE.HEX")
        assert_eq(error.offset, 0)
        assert_eq(error.expected, "even hex, at most 2048 octets")
        assert_eq(error.actual, text.length().to_string())
      }
      Ok(_) => fail("out of policy input accepted")
    }
  }
}
