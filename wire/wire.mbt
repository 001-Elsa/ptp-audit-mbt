///|
pub(all) enum Kind {
  Sync
  FollowUp
  DelayReq
  DelayResp
  Announce
} derive(Eq)

///|
pub fn Kind::code(self : Kind) -> Int32 {
  match self {
    Sync => 0
    FollowUp => 8
    DelayReq => 1
    DelayResp => 9
    Announce => 11
  }
}

///|
pub fn Kind::length(self : Kind) -> Int32 {
  match self {
    Sync | FollowUp | DelayReq => 44
    DelayResp => 54
    Announce => 64
  }
}

///|
pub fn Kind::control(self : Kind) -> Int32 {
  match self {
    Sync => 0
    DelayReq => 1
    FollowUp => 2
    DelayResp => 3
    Announce => 5
  }
}

///|
pub(all) struct PortIdentity {
  clock : String
  port : Int32
} derive(Eq)

///|
pub fn PortIdentity::label(self : PortIdentity) -> String {
  self.clock + ":" + self.port.to_string()
}

///|
pub(all) struct PtpTimestamp {
  seconds : Int64
  nanos : Int32
} derive(Eq)

///|
pub(all) struct Header {
  kind : Kind
  domain : Int32
  flags : Int32
  correction : Int64
  source : PortIdentity
  sequence : Int32
  log_interval : Int32
} derive(Eq)

///|
pub(all) struct AnnounceData {
  origin : PtpTimestamp
  utc_offset : Int32
  priority1 : Int32
  clock_class : Int32
  accuracy : Int32
  variance : Int32
  priority2 : Int32
  grandmaster : String
  steps_removed : Int32
  time_source : Int32
} derive(Eq)

///|
pub(all) enum Body {
  TimestampBody(PtpTimestamp)
  Response(PtpTimestamp, PortIdentity)
  Announcement(AnnounceData)
} derive(Eq)

///|
pub(all) struct Packet {
  header : Header
  body : Body
} derive(Eq)

///|
pub(all) struct WireError {
  status : @diagnostic.Status
  code : String
  offset : Int32
  expected : String
  actual : String
}

///|
fn error(
  code : String,
  offset : Int32,
  expected : String,
  actual : String,
  unsupported~ : Bool = false,
) -> WireError {
  {
    status: if unsupported {
      @diagnostic.Unsupported
    } else {
      @diagnostic.Violation
    },
    code,
    offset,
    expected,
    actual,
  }
}

///|
pub fn from_hex(text : String) -> Result[Bytes, WireError] {
  if text.length() % 2 != 0 || text.length() > 4096 {
    return Err(
      error(
        "WIRE.HEX",
        0,
        "even hex, at most 2048 octets",
        text.length().to_string(),
      ),
    )
  }
  Ok(@hex.decode(text[:])) catch {
    @hex.Malformed(_) => {
      // The standard decoder retains the input but has no error offset.
      // Locate the first rejected scalar only on its failure path; iter2
      // preserves UTF-16 offsets even for supplementary Unicode characters.
      for at, character in text.iter2() {
        ignore(@hex.decode((character.to_string() + "0")[:])) catch {
          @hex.Malformed(_) =>
            return Err(
              error("WIRE.HEX", at / 2, "hex octet", "non-hex character"),
            )
        }
      }
      Err(error("WIRE.HEX", 0, "hex octet", "non-hex character"))
    }
  }
}

///|
pub fn to_hex(b : Bytes) -> String {
  @hex.encode(b[:])
}

///|
fn uint_at(b : Bytes, at : Int32, count : Int32) -> Int64 {
  let mut n = 0L
  for i = at; i < at + count; i = i + 1 {
    n = (n << 8) | b[i].to_int().to_int64()
  }
  n
}

///|
fn put(b : Array[Byte], at : Int32, count : Int32, n : Int64) -> Unit {
  for i = 0; i < count; i = i + 1 {
    b[at + i] = ((n >> ((count - 1 - i) * 8)) & 255).to_int().to_byte()
  }
}

///|
fn identity_at(b : Bytes, at : Int32) -> String {
  let v = Array::make(8, b'\x00')
  for i = 0; i < 8; i = i + 1 {
    v[i] = b[at + i]
  }
  to_hex(Bytes::from_array(v))
}

///|
fn port_at(b : Bytes, at : Int32) -> PortIdentity {
  { clock: identity_at(b, at), port: uint_at(b, at + 8, 2).to_int(), }
}

///|
fn timestamp_at(b : Bytes, at : Int32) -> Result[PtpTimestamp, WireError] {
  let n = uint_at(b, at + 6, 4)
  if n >= 1_000_000_000L {
    Err(error("WIRE.NANOSECONDS", at + 6, "0..999999999", n.to_string()))
  } else {
    Ok({ seconds: uint_at(b, at, 6), nanos: n.to_int(), })
  }
}

///|
pub fn valid_port(p : PortIdentity) -> Bool {
  if p.clock.length() != 16 || p.port < 1 || p.port > 65535 {
    return false
  }
  match from_hex(p.clock) {
    Ok(b) => to_hex(b) == p.clock
    Err(_) => false
  }
}

///|
pub fn valid_time(t : PtpTimestamp) -> Bool {
  t.seconds >= 0L &&
  t.seconds <= 281474976710655L &&
  t.nanos >= 0 &&
  t.nanos < 1_000_000_000
}

///|
pub fn decode(b : Bytes) -> Result[Packet, WireError] {
  if b.length() < 34 {
    return Err(
      error(
        "WIRE.HEADER_LENGTH",
        0,
        "at least 34 octets",
        b.length().to_string(),
      ),
    )
  }
  if b[1].to_int() != 2 {
    return Err(
      error(
        "SCOPE.VERSION",
        1,
        "IEEE1588-2008 version octet 02",
        b[1].to_int().to_string(),
        unsupported=true,
      ),
    )
  }
  if b[0].to_int() >> 4 != 0 {
    return Err(
      error(
        "SCOPE.PROFILE",
        0,
        "transportSpecific=0",
        b[0].to_int().to_string(),
        unsupported=true,
      ),
    )
  }
  let kind = match b[0].to_int() & 15 {
    0 => Sync
    1 => DelayReq
    8 => FollowUp
    9 => DelayResp
    11 => Announce
    n =>
      return Err(
        error(
          "SCOPE.MESSAGE",
          0,
          "Sync/Follow_Up/Delay_Req/Delay_Resp/Announce",
          n.to_string(),
          unsupported=true,
        ),
      )
  }
  let declared = uint_at(b, 2, 2).to_int()
  if declared != b.length() {
    return Err(
      error(
        "WIRE.MESSAGE_LENGTH",
        2,
        b.length().to_string(),
        declared.to_string(),
      ),
    )
  }
  if declared < kind.length() {
    return Err(
      error(
        "WIRE.BODY_LENGTH",
        2,
        kind.length().to_string(),
        declared.to_string(),
      ),
    )
  }
  if declared > kind.length() {
    return Err(
      error(
        "SCOPE.TLV",
        kind.length(),
        "fixed body only",
        "extension octets",
        unsupported=true,
      ),
    )
  }
  for i in [5, 16, 17, 18, 19] {
    if b[i].to_int() != 0 {
      return Err(error("WIRE.RESERVED", i, "zero", b[i].to_int().to_string()))
    }
  }
  if b[32].to_int() != kind.control() {
    return Err(
      error(
        "WIRE.CONTROL",
        32,
        kind.control().to_string(),
        b[32].to_int().to_string(),
      ),
    )
  }
  let flags = uint_at(b, 6, 2).to_int()
  if kind != Sync && (flags & 0x0200) != 0 {
    return Err(
      error(
        "WIRE.TWO_STEP_FLAG",
        6,
        "twoStepFlag=0 for supported non-Sync messages",
        flags.to_string(),
      ),
    )
  }
  if uint_at(b, 8, 8) == -1L || uint_at(b, 8, 8) == 9223372036854775807L {
    return Err(
      error(
        "SCOPE.CORRECTION_TOO_BIG",
        8,
        "ordinary correction excluding ambiguous tooBig encodings from IEEE interpretations #25/#27",
        "tooBig/ambiguous encoding=" + uint_at(b, 8, 8).to_string(),
        unsupported=true,
      ),
    )
  }
  // 2008 defined flags; profile-specific/alternate-master/unicast behavior excluded.
  if (flags & 0xF8C0) != 0 {
    return Err(
      error(
        "SCOPE.FLAGS",
        6,
        "supported 2008 flags",
        flags.to_string(),
        unsupported=true,
      ),
    )
  }
  if (flags & 0x0500) != 0 {
    return Err(
      error(
        "SCOPE.MODE",
        6,
        "multicast, non-alternate-master",
        flags.to_string(),
        unsupported=true,
      ),
    )
  }
  let source = port_at(b, 20)
  if !valid_port(source) {
    return Err(
      error("WIRE.SOURCE_PORT", 28, "port 1..65535", source.port.to_string()),
    )
  }
  let interval = b[33].to_int()
  let header : Header = {
    kind,
    domain: b[4].to_int(),
    flags,
    correction: uint_at(b, 8, 8),
    source,
    sequence: uint_at(b, 30, 2).to_int(),
    log_interval: if interval >= 128 {
      interval - 256
    } else {
      interval
    },
  }
  let t = match timestamp_at(b, 34) {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  let body = match kind {
    DelayResp => {
      let requester = port_at(b, 44)
      if !valid_port(requester) {
        return Err(
          error(
            "WIRE.REQUESTER_PORT",
            52,
            "port 1..65535",
            requester.port.to_string(),
          ),
        )
      }
      Response(t, requester)
    }
    Announce => {
      if b[46].to_int() != 0 {
        return Err(
          error("WIRE.RESERVED", 46, "zero", b[46].to_int().to_string()),
        )
      }
      let utc = uint_at(b, 44, 2).to_int()
      Announcement({
        origin: t,
        utc_offset: if utc >= 32768 {
          utc - 65536
        } else {
          utc
        },
        priority1: b[47].to_int(),
        clock_class: b[48].to_int(),
        accuracy: b[49].to_int(),
        variance: uint_at(b, 50, 2).to_int(),
        priority2: b[52].to_int(),
        grandmaster: identity_at(b, 53),
        steps_removed: uint_at(b, 61, 2).to_int(),
        time_source: b[63].to_int(),
      })
    }
    _ => TimestampBody(t)
  }
  Ok({ header, body, })
}

///|
fn put_identity(b : Array[Byte], at : Int32, clock : String) -> Unit {
  match from_hex(clock) {
    Ok(v) =>
      for i = 0; i < 8; i = i + 1 {
        b[at + i] = v[i]
      }
    Err(_) => ()
  }
}

///|
fn put_port(b : Array[Byte], at : Int32, p : PortIdentity) -> Unit {
  put_identity(b, at, p.clock)
  put(b, at + 8, 2, p.port.to_int64())
}

///|
fn put_time(b : Array[Byte], at : Int32, t : PtpTimestamp) -> Unit {
  put(b, at, 6, t.seconds)
  put(b, at + 6, 4, t.nanos.to_int64())
}

///|
pub fn encode(p : Packet) -> Result[Bytes, WireError] {
  let h = p.header
  if !valid_port(h.source) ||
    h.domain < 0 ||
    h.domain > 255 ||
    h.sequence < 0 ||
    h.sequence > 65535 ||
    h.flags < 0 ||
    h.flags > 65535 ||
    h.log_interval < -128 ||
    h.log_interval > 127 {
    return Err(
      error(
        "WIRE.FIELD_RANGE", 0, "in-range header fields and canonical identity", "out of range",
      ),
    )
  }
  let b = Array::make(h.kind.length(), b'\x00')
  b[0] = h.kind.code().to_byte()
  b[1] = b'\x02'
  put(b, 2, 2, h.kind.length().to_int64())
  b[4] = h.domain.to_byte()
  put(b, 6, 2, h.flags.to_int64())
  put(b, 8, 8, h.correction)
  put_port(b, 20, h.source)
  put(b, 30, 2, h.sequence.to_int64())
  b[32] = h.kind.control().to_byte()
  b[33] = (h.log_interval & 255).to_byte()
  match (h.kind, p.body) {
    (Sync | FollowUp | DelayReq, TimestampBody(t)) => {
      if !valid_time(t) {
        return Err(
          error(
            "WIRE.TIMESTAMP", 34, "48-bit seconds; nanos<1e9", "out of range",
          ),
        )
      }
      put_time(b, 34, t)
    }
    (DelayResp, Response(t, r)) => {
      if !valid_time(t) || !valid_port(r) {
        return Err(
          error(
            "WIRE.RESPONSE", 34, "valid timestamp and requester", "out of range",
          ),
        )
      }
      put_time(b, 34, t)
      put_port(b, 44, r)
    }
    (Announce, Announcement(a)) => {
      if !valid_time(a.origin) ||
        a.utc_offset < -32768 ||
        a.utc_offset > 32767 ||
        a.priority1 < 0 ||
        a.priority1 > 255 ||
        a.clock_class < 0 ||
        a.clock_class > 255 ||
        a.accuracy < 0 ||
        a.accuracy > 255 ||
        a.variance < 0 ||
        a.variance > 65535 ||
        a.priority2 < 0 ||
        a.priority2 > 255 ||
        !valid_port({ clock: a.grandmaster, port: 1, }) ||
        a.steps_removed < 0 ||
        a.steps_removed > 65535 ||
        a.time_source < 0 ||
        a.time_source > 255 {
        return Err(
          error("WIRE.ANNOUNCE", 34, "in-range announce fields", "out of range"),
        )
      }
      put_time(b, 34, a.origin)
      put(b, 44, 2, (a.utc_offset & 65535).to_int64())
      b[47] = a.priority1.to_byte()
      b[48] = a.clock_class.to_byte()
      b[49] = a.accuracy.to_byte()
      put(b, 50, 2, a.variance.to_int64())
      b[52] = a.priority2.to_byte()
      put_identity(b, 53, a.grandmaster)
      put(b, 61, 2, a.steps_removed.to_int64())
      b[63] = a.time_source.to_byte()
    }
    _ =>
      return Err(
        error("WIRE.BODY_KIND", 34, "body matches header kind", "mismatch"),
      )
  }
  let bytes = Bytes::from_array(b)
  match decode(bytes) {
    Ok(_) => Ok(bytes)
    Err(e) => Err(e)
  }
}

///|
pub extend Kind with Eq::{equal, not_equal}

///|
pub extend PortIdentity with Eq::{equal, not_equal}

///|
pub extend PtpTimestamp with Eq::{equal, not_equal}

///|
pub extend Header with Eq::{equal, not_equal}

///|
pub extend AnnounceData with Eq::{equal, not_equal}

///|
pub extend Body with Eq::{equal, not_equal}

///|
pub extend Packet with Eq::{equal, not_equal}
