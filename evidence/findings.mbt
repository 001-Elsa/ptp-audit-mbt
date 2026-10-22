///|
fn requester_json(frame : @exchange.Frame) -> Json {
  match frame.packet.body {
    @wire.Response(_, requester) => port_json(requester)
    _ => Json::null()
  }
}

///|
fn association_key(frame : @exchange.Frame) -> Json {
  Json::object({
    "frame": number(frame.id),
    "message_type": Json::string(kind_label(frame.packet.header.kind)),
    "epoch": integer_or_null(frame.epoch),
    "window": string_or_null(frame.window),
    "capture_clock_domain": string_or_null(frame.capture_clock_domain),
    "capture_time": optional_timestamp_json(frame.capture_time),
    "domain_number": number(frame.packet.header.domain),
    "source_port_identity": port_json(frame.packet.header.source),
    "sequence_id": number(frame.packet.header.sequence),
    "requesting_port_identity": requester_json(frame),
  })
}

///|
fn comparison(
  name : String,
  left_frame : Int32,
  right_frame : Int32,
  left : Json,
  right : Json,
  required_relation : String,
) -> Json {
  Json::object({
    "field": Json::string(name),
    "left_frame": number(left_frame),
    "right_frame": number(right_frame),
    "left_value": left,
    "right_value": right,
    "equal": if left == Json::null() || right == Json::null() {
      Json::null()
    } else {
      Json::boolean(left == right)
    },
    "relation": Json::string(required_relation),
    "missing_value_semantics": Json::string(
      "A null value cannot establish equality; the finding status determines whether evidence was sufficient.",
    ),
  })
}

///|
fn shared_context_comparisons(
  left : @exchange.Frame,
  right : @exchange.Frame,
) -> Array[Json] {
  [
    comparison(
      "epoch",
      left.id,
      right.id,
      integer_or_null(left.epoch),
      integer_or_null(right.epoch),
      "same explicitly supplied observation epoch",
    ),
    comparison(
      "window",
      left.id,
      right.id,
      string_or_null(left.window),
      string_or_null(right.window),
      "same explicitly supplied observation window",
    ),
    comparison(
      "capture_clock_domain",
      left.id,
      right.id,
      string_or_null(left.capture_clock_domain),
      string_or_null(right.capture_clock_domain),
      "same capture clock for freshness arithmetic",
    ),
    comparison(
      "domainNumber",
      left.id,
      right.id,
      number(left.packet.header.domain),
      number(right.packet.header.domain),
      "same PTP domain",
    ),
  ]
}

///|
fn source_comparison(left : @exchange.Frame, right : @exchange.Frame) -> Json {
  comparison(
    "sourcePortIdentity",
    left.id,
    right.id,
    port_json(left.packet.header.source),
    port_json(right.packet.header.source),
    "same sender identity for the specified master-message association",
  )
}

///|
fn sequence_comparison(left : @exchange.Frame, right : @exchange.Frame) -> Json {
  comparison(
    "sequenceId",
    left.id,
    right.id,
    number(left.packet.header.sequence),
    number(right.packet.header.sequence),
    "equal for this pair; no numeric ordering or cross-message-family equality is assumed",
  )
}

///|
fn association_comparisons(
  finding : @diagnostic.Finding,
  frames : Array[@exchange.Frame],
) -> Array[Json] {
  if frames.length() < 2 {
    return []
  }
  let first = frames[0]
  let comparisons = []
  let bmca = finding.rule.has_prefix("BMCA.")
  for i = 1; i < frames.length(); i = i + 1 {
    for check in shared_context_comparisons(first, frames[i]) {
      comparisons.push(check)
    }
  }
  if bmca {
    // Different candidate sources and sequence ids are expected in BMCA. All
    // dataset values remain available in each complete frame projection.
    return comparisons
  }
  if frames.length() == 4 &&
    (
      finding.rule == "CLAIM.E2E_IDENTITY" ||
      finding.rule == "CLAIM.EXCHANGE_WINDOW" ||
      finding.rule.has_prefix("MEASUREMENT.")
    ) {
    let sync = frames[0]
    let follow_up = frames[1]
    let request = frames[2]
    let response = frames[3]
    comparisons.push(source_comparison(sync, follow_up))
    comparisons.push(sequence_comparison(sync, follow_up))
    comparisons.push(sequence_comparison(request, response))
    comparisons.push(source_comparison(sync, response))
    comparisons.push(
      comparison(
        "Delay_Resp.requestingPortIdentity vs Delay_Req.sourcePortIdentity",
        response.id,
        request.id,
        requester_json(response),
        port_json(request.packet.header.source),
        "response names the requesting port of this delay request",
      ),
    )
    comparisons.push(
      comparison(
        "local event clock domain",
        sync.id,
        request.id,
        string_or_null(sync.clock_domain),
        string_or_null(request.clock_domain),
        "t2 and t3 refer to the same local slave clock domain",
      ),
    )
    comparisons.push(
      comparison(
        "local event port vs requesting port",
        sync.id,
        request.id,
        optional_port_json(sync.local_port),
        port_json(request.packet.header.source),
        "Sync reception metadata belongs to the requesting slave port",
      ),
    )
    comparisons.push(
      comparison(
        "Delay_Req event port vs source port",
        request.id,
        request.id,
        optional_port_json(request.local_port),
        port_json(request.packet.header.source),
        "Delay_Req transmit metadata belongs to its source slave port",
      ),
    )
  } else if finding.rule == "CLAIM.DELAY_WINDOW" {
    let request = frames[0]
    let response = frames[1]
    comparisons.push(sequence_comparison(request, response))
    comparisons.push(
      comparison(
        "Delay_Resp.requestingPortIdentity vs Delay_Req.sourcePortIdentity",
        response.id,
        request.id,
        requester_json(response),
        port_json(request.packet.header.source),
        "response names the requesting port; request and response source identities are not required to match",
      ),
    )
  } else if finding.rule == "EXCHANGE.SYNC_FOLLOW_UP" ||
    finding.rule == "EXCHANGE.WINDOW" ||
    finding.rule == "CLAIM.SYNC_FOLLOW_UP" ||
    finding.rule == "CLAIM.SYNC_WINDOW" {
    comparisons.push(source_comparison(first, frames[1]))
    comparisons.push(sequence_comparison(first, frames[1]))
  }
  comparisons
}

///|
pub fn finding_json(
  finding : @diagnostic.Finding,
  frames : Array[@exchange.Frame],
  context : @observation.Context,
  assumptions : Json,
  bmca_input : Json?,
) -> Json {
  let resolved = []
  let missing = []
  let duplicate_ids = []
  for id in finding.frames {
    let matching = frames.filter(fn(frame) { frame.id == id })
    if matching.is_empty() {
      missing.push(id)
    } else {
      for frame in matching {
        resolved.push(frame)
      }
      if matching.length() > 1 {
        duplicate_ids.push(id)
      }
    }
  }
  // The typed Finding keeps expected/actual as short strings for callers and
  // CLI diagnostics.  The report, however, is the evidence boundary: expose
  // the concrete JSON values there so a consumer never has to infer what
  // “matching” or “mismatching” referred to from a label alone.
  let comparisons = association_comparisons(finding, resolved)
  let expected = Json::object({
    "summary": Json::string(finding.expected),
    "frame_ids": ids_json(finding.frames),
    "field_comparisons": Json::array(comparisons),
    "observation_context": context.to_json(),
    "assumptions": assumptions,
    "bmca_snapshot": match bmca_input {
      Some(value) => value
      None => Json::null()
    },
  })
  let actual = Json::object({
    "summary": Json::string(finding.actual),
    "frame_ids": ids_json(finding.frames),
    "referenced_frames": Json::array(
      resolved.map(fn(frame) { frame_json(frame) }),
    ),
    "association_keys": Json::array(
      resolved.map(fn(frame) { association_key(frame) }),
    ),
    "field_comparisons": Json::array(comparisons),
    "observation_context": context.to_json(),
    "assumptions": assumptions,
    "bmca_snapshot": match bmca_input {
      Some(value) => value
      None => Json::null()
    },
  })
  Json::object({
    "rule": Json::string(finding.rule),
    "status": Json::string(finding.status.label()),
    "frames": ids_json(finding.frames),
    "offset": integer_or_null(finding.offset),
    "expected": expected,
    "actual": actual,
    "detail": Json::string(finding.detail),
    "evidence": Json::object({
      "referenced_frames": Json::array(
        resolved.map(fn(frame) { frame_json(frame) }),
      ),
      "unresolved_frame_ids": ids_json(missing),
      "ambiguous_frame_ids": ids_json(duplicate_ids),
      "association_keys": Json::array(
        resolved.map(fn(frame) { association_key(frame) }),
      ),
      "field_comparisons": Json::array(comparisons),
      "observation_context": context.to_json(),
      "supplied_assumptions": assumptions,
      "supplied_bmca_snapshot": match bmca_input {
        Some(value) => value
        None => Json::null()
      },
      "interpretation": Json::string(
        "Concrete values supplement expected/actual text. Equality of a displayed field alone is not a protocol verdict; use this finding's rule, status, metadata preconditions and rule_reference.",
      ),
    }),
    "rule_reference": rule_reference_json(finding.rule),
  })
}
