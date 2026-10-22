///|
fn number(value : Int32) -> Json {
  Json::number(value.to_double())
}

///|
fn string_or_null(value : String?) -> Json {
  match value {
    Some(v) => Json::string(v)
    None => Json::null()
  }
}

///|
fn integer_or_null(value : Int32?) -> Json {
  match value {
    Some(v) => number(v)
    None => Json::null()
  }
}

///|
fn ids_json(ids : Array[Int32]) -> Json {
  Json::array(ids.map(fn(id) { number(id) }))
}

///|
fn strings_json(values : Array[String]) -> Json {
  Json::array(values.map(fn(value) { Json::string(value) }))
}

///|
fn time_nanos(value : @wire.PtpTimestamp) -> String {
  (@bigint.BigInt::from_int64(value.seconds) *
  @bigint.BigInt::from_int(1_000_000_000) +
  @bigint.BigInt::from_int(value.nanos)).to_string()
}

///|
fn timestamp_json(value : @wire.PtpTimestamp) -> Json {
  Json::object({
    "seconds_decimal": Json::string(value.seconds.to_string()),
    "nanoseconds": number(value.nanos),
    "total_nanoseconds_decimal": Json::string(time_nanos(value)),
    "representation": Json::string("seconds * 1000000000 + nanoseconds"),
  })
}

///|
fn optional_timestamp_json(value : @wire.PtpTimestamp?) -> Json {
  match value {
    Some(t) => timestamp_json(t)
    None => Json::null()
  }
}

///|
fn port_json(value : @wire.PortIdentity) -> Json {
  Json::object({
    "clock_identity_hex": Json::string(value.clock),
    "port_number": number(value.port),
    "label": Json::string(value.label()),
  })
}

///|
fn optional_port_json(value : @wire.PortIdentity?) -> Json {
  match value {
    Some(p) => port_json(p)
    None => Json::null()
  }
}

///|
fn kind_label(kind : @wire.Kind) -> String {
  match kind {
    @wire.Sync => "Sync"
    @wire.FollowUp => "Follow_Up"
    @wire.DelayReq => "Delay_Req"
    @wire.DelayResp => "Delay_Resp"
    @wire.Announce => "Announce"
  }
}

///|
fn field(name : String, offset : Int32, octets : Int32, value : Json) -> Json {
  Json::object({
    "name": Json::string(name),
    "byte_offset": number(offset),
    "octet_length": number(octets),
    "value": value,
  })
}

///|
fn header_fields(header : @wire.Header) -> Array[Json] {
  [
    field("transportSpecific", 0, 1, number(0)),
    field("messageType", 0, 1, number(header.kind.code())),
    field("versionPTP", 1, 1, number(2)),
    field("messageLength", 2, 2, number(header.kind.length())),
    field("domainNumber", 4, 1, number(header.domain)),
    field("reserved1", 5, 1, number(0)),
    field("flagField", 6, 2, number(header.flags)),
    field(
      "correctionField",
      8,
      8,
      Json::object({
        "signed_scaled_nanoseconds_decimal": Json::string(
          header.correction.to_string(),
        ),
        "nanoseconds_denominator": number(65536),
      }),
    ),
    field("reserved2", 16, 4, number(0)),
    field(
      "sourcePortIdentity.clockIdentity",
      20,
      8,
      Json::string(header.source.clock),
    ),
    field("sourcePortIdentity.portNumber", 28, 2, number(header.source.port)),
    field("sequenceId", 30, 2, number(header.sequence)),
    field("controlField", 32, 1, number(header.kind.control())),
    field("logMessageInterval", 33, 1, number(header.log_interval)),
  ]
}

///|
fn body_fields(packet : @wire.Packet) -> Array[Json] {
  let fields = []
  let stamp = match packet.body {
    @wire.TimestampBody(t) | @wire.Response(t, _) => t
    @wire.Announcement(a) => a.origin
  }
  let timestamp_name = match packet.header.kind {
    @wire.FollowUp => "preciseOriginTimestamp"
    @wire.DelayResp => "receiveTimestamp"
    _ => "originTimestamp"
  }
  fields.push(
    field(
      timestamp_name + ".secondsField",
      34,
      6,
      Json::string(stamp.seconds.to_string()),
    ),
  )
  fields.push(
    field(timestamp_name + ".nanosecondsField", 40, 4, number(stamp.nanos)),
  )
  match packet.body {
    @wire.Response(_, requester) => {
      fields.push(
        field(
          "requestingPortIdentity.clockIdentity",
          44,
          8,
          Json::string(requester.clock),
        ),
      )
      fields.push(
        field(
          "requestingPortIdentity.portNumber",
          52,
          2,
          number(requester.port),
        ),
      )
    }
    @wire.Announcement(a) => {
      fields.push(field("currentUtcOffset", 44, 2, number(a.utc_offset)))
      fields.push(field("reserved", 46, 1, number(0)))
      fields.push(field("grandmasterPriority1", 47, 1, number(a.priority1)))
      fields.push(
        field(
          "grandmasterClockQuality.clockClass",
          48,
          1,
          number(a.clock_class),
        ),
      )
      fields.push(
        field(
          "grandmasterClockQuality.clockAccuracy",
          49,
          1,
          number(a.accuracy),
        ),
      )
      fields.push(
        field(
          "grandmasterClockQuality.offsetScaledLogVariance",
          50,
          2,
          number(a.variance),
        ),
      )
      fields.push(field("grandmasterPriority2", 52, 1, number(a.priority2)))
      fields.push(
        field("grandmasterIdentity", 53, 8, Json::string(a.grandmaster)),
      )
      fields.push(field("stepsRemoved", 61, 2, number(a.steps_removed)))
      fields.push(field("timeSource", 63, 1, number(a.time_source)))
    }
    _ => ()
  }
  fields
}

///|
fn body_json(packet : @wire.Packet) -> Json {
  match packet.body {
    @wire.TimestampBody(t) => Json::object({ "timestamp": timestamp_json(t) })
    @wire.Response(t, requester) =>
      Json::object({
        "receive_timestamp": timestamp_json(t),
        "requesting_port_identity": port_json(requester),
      })
    @wire.Announcement(a) =>
      Json::object({
        "origin_timestamp": timestamp_json(a.origin),
        "current_utc_offset": number(a.utc_offset),
        "grandmaster_priority1": number(a.priority1),
        "grandmaster_clock_class": number(a.clock_class),
        "grandmaster_clock_accuracy": number(a.accuracy),
        "grandmaster_offset_scaled_log_variance": number(a.variance),
        "grandmaster_priority2": number(a.priority2),
        "grandmaster_identity": Json::string(a.grandmaster),
        "steps_removed": number(a.steps_removed),
        "time_source": number(a.time_source),
      })
  }
}

///|
pub fn frame_json(frame : @exchange.Frame) -> Json {
  let h = frame.packet.header
  Json::object({
    "id": number(frame.id),
    "observation": Json::object({
      "epoch": integer_or_null(frame.epoch),
      "window": string_or_null(frame.window),
      "capture_time": optional_timestamp_json(frame.capture_time),
      "capture_clock_domain": string_or_null(frame.capture_clock_domain),
      "local_port": optional_port_json(frame.local_port),
      "event_time": optional_timestamp_json(frame.event_time),
      "clock_domain": string_or_null(frame.clock_domain),
      "direction": string_or_null(frame.direction),
      "trust": Json::string(
        "Caller-supplied metadata; not authenticated by this auditor.",
      ),
    }),
    "header": Json::object({
      "message_type": Json::string(kind_label(h.kind)),
      "message_type_code": number(h.kind.code()),
      "transport_specific": number(0),
      "version": number(2),
      "message_length": number(h.kind.length()),
      "domain_number": number(h.domain),
      "flags": number(h.flags),
      "two_step_flag": Json::boolean((h.flags & 512) != 0),
      "correction_scaled_nanoseconds_decimal": Json::string(
        h.correction.to_string(),
      ),
      "correction_nanoseconds_denominator": number(65536),
      "source_port_identity": port_json(h.source),
      "sequence_id": number(h.sequence),
      "control": number(h.kind.control()),
      "log_message_interval": number(h.log_interval),
    }),
    "body": body_json(frame.packet),
    "wire_fields": Json::array(header_fields(h) + body_fields(frame.packet)),
    "wire_field_notice": Json::string(
      "Offsets are zero-based from the PTP message start, without Ethernet/IP/UDP headers. Constant reserved/profile fields describe the accepted fixed-body subset; this is a decoded typed packet, not a copy of rejected raw input.",
    ),
  })
}
