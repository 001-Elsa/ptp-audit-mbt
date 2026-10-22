///|
fn measurement_frame(
  ids : Array[Int32],
  index : Int32,
  frames : Array[@exchange.Frame],
) -> @exchange.Frame? {
  if index >= ids.length() {
    return None
  }
  let matches = frames.filter(fn(frame) { frame.id == ids[index] })
  if matches.length() == 1 {
    Some(matches[0])
  } else {
    None
  }
}

///|
fn packet_time(frame : @exchange.Frame) -> @wire.PtpTimestamp {
  match frame.packet.body {
    @wire.TimestampBody(time) | @wire.Response(time, _) => time
    @wire.Announcement(data) => data.origin
  }
}

///|
fn timestamp_operand(
  name : String,
  frame : @exchange.Frame?,
  packet_field : Bool,
  source : String,
  role : String,
) -> Json {
  match frame {
    None =>
      Json::object({
        "name": Json::string(name),
        "value": Json::null(),
        "source": Json::string(source),
        "notice": Json::string(
          "Referenced frame is absent or ambiguous; no evidence reconstructed.",
        ),
      })
    Some(frame) => {
      let time = if packet_field {
        Some(packet_time(frame))
      } else {
        frame.event_time
      }
      Json::object({
        "name": Json::string(name),
        "frame": number(frame.id),
        "value": optional_timestamp_json(time),
        "source": Json::string(source),
        "byte_offset": if packet_field {
          number(34)
        } else {
          Json::null()
        },
        "clock_role": Json::string(role),
        "event_clock_domain": if packet_field {
          Json::null()
        } else {
          string_or_null(frame.clock_domain)
        },
        "direction": string_or_null(frame.direction),
        "epoch": integer_or_null(frame.epoch),
        "window": string_or_null(frame.window),
        "packet_source_identity": port_json(frame.packet.header.source),
        "local_port": optional_port_json(frame.local_port),
      })
    }
  }
}

///|
fn correction_operand(
  name : String,
  frame : @exchange.Frame?,
  used : Bool,
) -> Json {
  Json::object({
    "name": Json::string(name),
    "frame": match frame {
      Some(value) => number(value.id)
      None => Json::null()
    },
    "signed_scaled_nanoseconds_decimal": match frame {
      Some(value) => Json::string(value.packet.header.correction.to_string())
      None => Json::null()
    },
    "nanoseconds_denominator": number(65536),
    "byte_offset": number(8),
    "octet_length": number(8),
    "subtracted_in_this_measurement": Json::boolean(used),
  })
}

///|
/// All large quantities remain decimal strings. Timestamp provenance is
/// displayed separately from arithmetic so a numerical result cannot imply
/// authenticated hardware capture or known path asymmetry.
pub fn measurement_json(
  measurement : @exchange.Measurement,
  frames : Array[@exchange.Frame],
) -> Json {
  let sync = measurement_frame(measurement.frames, 0, frames)
  let follow_up = measurement_frame(measurement.frames, 1, frames)
  let request = measurement_frame(measurement.frames, 2, frames)
  let response = measurement_frame(measurement.frames, 3, frames)
  Json::object({
    "frames": ids_json(measurement.frames),
    "frame_order": strings_json(["Sync", "Follow_Up", "Delay_Req", "Delay_Resp"]),
    "offset_numerator": Json::string(measurement.offset_numerator),
    "mean_delay_numerator": Json::string(measurement.delay_numerator),
    "denominator": number(measurement.denominator),
    "unit": Json::string("ns"),
    "timestamps": Json::array([
      timestamp_operand(
        "t1", follow_up, true, "Follow_Up.preciseOriginTimestamp", "master transmit clock",
      ),
      timestamp_operand(
        "t2", sync, false, "Sync.event_time (caller-supplied reception event)", "slave receive clock",
      ),
      timestamp_operand(
        "t3", request, false, "Delay_Req.event_time (caller-supplied transmit event)",
        "slave transmit clock",
      ),
      timestamp_operand(
        "t4", response, true, "Delay_Resp.receiveTimestamp", "master receive clock",
      ),
    ]),
    "corrections": Json::array([
      correction_operand("Sync.correctionField", sync, true),
      correction_operand("Follow_Up.correctionField", follow_up, true),
      correction_operand("Delay_Resp.correctionField", response, true),
      correction_operand("Delay_Req.correctionField", request, false),
    ]),
    "intermediate": Json::object({
      "forward_scaled_nanoseconds_decimal": Json::string(
        measurement.forward_scaled,
      ),
      "reverse_scaled_nanoseconds_decimal": Json::string(
        measurement.reverse_scaled,
      ),
      "sync_plus_follow_up_correction_scaled_nanoseconds_decimal": Json::string(
        measurement.sync_correction_scaled,
      ),
      "delay_response_correction_scaled_nanoseconds_decimal": Json::string(
        measurement.delay_correction_scaled,
      ),
      "scaled_nanoseconds_denominator": number(65536),
    }),
    "formulas": Json::object({
      "timestamp_unit": Json::string(
        "N(t) = seconds(t) * 1000000000 + nanoseconds(t)",
      ),
      "forward": Json::string(
        "F = (N(t2) - N(t1)) * 65536 - Sync.correctionField - Follow_Up.correctionField",
      ),
      "reverse": Json::string(
        "R = (N(t4) - N(t3)) * 65536 - Delay_Resp.correctionField",
      ),
      "offset_ns": Json::string("(F - R) / 131072"),
      "mean_path_delay_ns": Json::string("(F + R) / 131072"),
      "delay_request_correction": Json::string(
        "Delay_Req.correctionField is displayed for traceability and is not subtracted again; the response correction is the delay-path correction operand.",
      ),
    }),
    "calculation_precision": Json::string(
      "Exact integer arithmetic; final numerator/denominator is a rational number in nanoseconds.",
    ),
    "accuracy_boundary": Json::string(
      "Algebraic precision is not absolute clock accuracy. Result is conditional on caller-confirmed timestamp provenance, matching event clock domain, symmetric paths and stable relative rates; capture authenticity, hardware latency and path asymmetry are not inferred.",
    ),
    "rule_reference": rule_reference_json("MEASUREMENT.E2E"),
  })
}
