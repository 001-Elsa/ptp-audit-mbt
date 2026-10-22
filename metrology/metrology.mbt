///|
/// Caller-supplied, conservative absolute error bounds, in units of 1/65536 ns.
/// Timestamp bounds are ordered t1, t2, t3, t4 and must include any relative-rate
/// error over this exchange. The correction bound covers the sum of absolute
/// errors of Sync, Follow_Up and Delay_Resp correction operands. The asymmetry
/// bound limits abs(forward path delay - reverse path delay), not either delay.
/// Source and assumptions are declarations, not authenticated calibration.
pub(all) struct ErrorBudget {
  timestamp_error_bounds_scaled : Array[String]
  correction_error_bound_scaled : String
  path_asymmetry_bound_scaled : String
  offset_limit_scaled : String
  source : String
  assumptions : String
  relative_rate_bound_confirmed : Bool
}

///|
pub(all) struct CorrectionContribution {
  frame : Int32
  field : String
  correction_scaled : String
  offset_numerator : String
  delay_numerator : String
  included : Bool
}

///|
pub(all) struct CorrectionLedger {
  uncorrected_offset_numerator : String
  uncorrected_delay_numerator : String
  corrected_offset_numerator : String
  corrected_delay_numerator : String
  denominator : Int32
  forward_raw_scaled : String
  reverse_raw_scaled : String
  contributions : Array[CorrectionContribution]
}

///|
pub(all) struct Assessment {
  verdict : String
  lower_numerator : String
  upper_numerator : String
  radius_numerator : String
  limit_numerator : String
  denominator : Int32
  budget : ErrorBudget
}

///|
pub(all) struct Explanation {
  frames : Array[Int32]
  status : @diagnostic.Status
  detail : String
  ledger : CorrectionLedger?
  assessment : Assessment?
}

///|
fn failure(
  ids : Array[Int32],
  status : @diagnostic.Status,
  detail : String,
  ledger~ : CorrectionLedger? = None,
) -> Explanation {
  { frames: ids, status, detail, ledger, assessment: None, }
}

///|
/// Canonical base-ten integers only; bounded before BigInt construction.
fn decimal(text : String, signed~ : Bool) -> @bigint.BigInt? {
  if text.length() == 0 || text.length() > 256 {
    return None
  }
  let start = if text.code_unit_at(0).to_int() == 45 && signed { 1 } else { 0 }
  if start == text.length() || (start == 1 && text == "-0") {
    return None
  }
  if text.length() - start > 1 && text.code_unit_at(start).to_int() == 48 {
    return None
  }
  for i = start; i < text.length(); i = i + 1 {
    let digit = text.code_unit_at(i).to_int()
    if digit < 48 || digit > 57 {
      return None
    }
  }
  Some(@bigint.BigInt::from_string(text))
}

///|
fn unique_frame(
  ids : Array[Int32],
  index : Int32,
  frames : Array[@exchange.Frame],
) -> @exchange.Frame? {
  let found = frames.filter(fn(frame) { frame.id == ids[index] })
  if found.length() == 1 {
    Some(found[0])
  } else {
    None
  }
}

///|
fn contribution(
  frame : @exchange.Frame,
  offset_sign : Int32,
  included : Bool,
  field : String,
) -> CorrectionContribution {
  let c = @bigint.BigInt::from_int64(frame.packet.header.correction)
  {
    frame: frame.id,
    field,
    correction_scaled: c.to_string(),
    offset_numerator: (c * @bigint.BigInt::from_int(offset_sign)).to_string(),
    delay_numerator: if included {
      (-c).to_string()
    } else {
      "0"
    },
    included,
  }
}

///|
fn assess(
  ledger : CorrectionLedger,
  ids : Array[Int32],
  budget : ErrorBudget,
) -> Explanation {
  if !@observation.text_ok(budget.source, 4096) ||
    !@observation.text_ok(budget.assumptions, 4096) ||
    !budget.relative_rate_bound_confirmed {
    return failure(
      ids,
      @diagnostic.InsufficientEvidence,
      "A nonempty bound source, exchange-specific assumptions and confirmation that timestamp bounds include relative-rate error are required; no accuracy verdict inferred.",
      ledger=Some(ledger),
    )
  }
  if budget.timestamp_error_bounds_scaled.length() != 4 {
    return failure(
      ids,
      @diagnostic.Violation,
      "Exactly four timestamp error bounds are required, ordered t1, t2, t3, t4.",
      ledger=Some(ledger),
    )
  }
  let mut radius = @bigint.BigInt::from_int(0)
  let values = budget.timestamp_error_bounds_scaled.copy()
  values.push(budget.correction_error_bound_scaled)
  values.push(budget.path_asymmetry_bound_scaled)
  for value in values {
    match decimal(value, signed=false) {
      Some(bound) => radius = radius + bound
      None =>
        return failure(
          ids,
          @diagnostic.Violation,
          "Every error/asymmetry bound must be a canonical nonnegative decimal scaled-ns integer of at most 256 characters.",
          ledger=Some(ledger),
        )
    }
  }
  let limit = match decimal(budget.offset_limit_scaled, signed=false) {
    Some(value) => value * @bigint.BigInt::from_int(2)
    None =>
      return failure(
        ids,
        @diagnostic.Violation,
        "The offset limit must be a canonical nonnegative decimal scaled-ns integer of at most 256 characters.",
        ledger=Some(ledger),
      )
  }
  let center = @bigint.BigInt::from_string(ledger.corrected_offset_numerator)
  let lower = center - radius
  let upper = center + radius
  let magnitude = if center < @bigint.BigInt::from_int(0) {
    -center
  } else {
    center
  }
  let verdict = if magnitude + radius <= limit {
    "within_limit"
  } else if lower > limit || upper < -limit {
    "outside_limit"
  } else {
    "indeterminate"
  }
  {
    frames: ids,
    status: @diagnostic.Pass,
    detail: "Conditional interval only: caller-supplied bounds and provenance are not authenticated. Outside/within describes the stated offset limit, not protocol conformance or hardware certification.",
    ledger: Some(ledger),
    assessment: Some({
      verdict,
      lower_numerator: lower.to_string(),
      upper_numerator: upper.to_string(),
      radius_numerator: radius.to_string(),
      limit_numerator: limit.to_string(),
      denominator: 131072,
      budget,
    }),
  }
}

///|
/// Explains an accepted exchange measurement, not an alternative exchange
/// validator. It rechecks unique frame references, PTP quartet identities,
/// shared observation labels, timestamp operands and every measurement integer.
/// Only exchange.audit with its Context establishes valid windows, qualification
/// and caller-confirmed timestamp/path/rate prerequisites.
pub fn explain(
  measurement : @exchange.Measurement,
  frames : Array[@exchange.Frame],
  budget : ErrorBudget?,
) -> Explanation {
  let ids = measurement.frames
  if ids.length() != 4 || measurement.denominator != 131072 {
    return failure(
      ids,
      @diagnostic.Violation,
      "A four-frame E2E measurement with denominator 131072 is required.",
    )
  }
  for i = 0; i < 4; i = i + 1 {
    for j = i + 1; j < 4; j = j + 1 {
      if ids[i] == ids[j] {
        return failure(
          ids,
          @diagnostic.Violation,
          "The four measurement frame IDs must be distinct.",
        )
      }
    }
  }
  let (s, f, q, r) = match
    (
      unique_frame(ids, 0, frames),
      unique_frame(ids, 1, frames),
      unique_frame(ids, 2, frames),
      unique_frame(ids, 3, frames),
    ) {
    (Some(s), Some(f), Some(q), Some(r)) => (s, f, q, r)
    _ =>
      return failure(
        ids,
        @diagnostic.InsufficientEvidence,
        "A referenced quartet frame is absent or ambiguous; no ledger reconstructed.",
      )
  }
  let hs = s.packet.header
  let hf = f.packet.header
  let hq = q.packet.header
  let hr = r.packet.header
  if hs.kind != @wire.Sync ||
    hf.kind != @wire.FollowUp ||
    hq.kind != @wire.DelayReq ||
    hr.kind != @wire.DelayResp ||
    hs.domain != hf.domain ||
    hs.domain != hq.domain ||
    hs.domain != hr.domain ||
    hs.source != hf.source ||
    hs.source != hr.source ||
    hs.sequence != hf.sequence ||
    hq.sequence != hr.sequence {
    return failure(
      ids,
      @diagnostic.Violation,
      "PTP quartet kind, domain, master identity or sequence relationship contradicts the supplied measurement.",
    )
  }
  if s.epoch is None ||
    s.window is None ||
    s.capture_clock_domain is None ||
    s.epoch != f.epoch ||
    s.epoch != q.epoch ||
    s.epoch != r.epoch ||
    s.window != f.window ||
    s.window != q.window ||
    s.window != r.window ||
    s.capture_clock_domain != f.capture_clock_domain ||
    s.capture_clock_domain != q.capture_clock_domain ||
    s.capture_clock_domain != r.capture_clock_domain {
    return failure(
      ids,
      @diagnostic.InsufficientEvidence,
      "Explicit shared epoch, observation window and capture-clock labels are required; window validity remains the exchange auditor's prerequisite.",
    )
  }
  let (t1, t2, t3, t4) = match
    (f.packet.body, s.event_time, q.event_time, r.packet.body) {
    (@wire.TimestampBody(t1), Some(t2), Some(t3), @wire.Response(t4, requester)) => {
      if requester != hq.source {
        return failure(
          ids,
          @diagnostic.Violation,
          "Delay_Resp requester does not match Delay_Req source identity.",
        )
      }
      (t1, t2, t3, t4)
    }
    _ =>
      return failure(
        ids,
        @diagnostic.InsufficientEvidence,
        "The accepted measurement's t1..t4 operands are unavailable.",
      )
  }
  if !@wire.valid_time(t1) ||
    !@wire.valid_time(t2) ||
    !@wire.valid_time(t3) ||
    !@wire.valid_time(t4) ||
    s.local_port != Some(hq.source) ||
    q.local_port != Some(hq.source) ||
    s.direction != Some("rx") ||
    q.direction != Some("tx") ||
    s.clock_domain is None ||
    s.clock_domain != q.clock_domain {
    return failure(
      ids,
      @diagnostic.InsufficientEvidence,
      "Timestamp validity, shared slave clock, local port or receive/transmit provenance is incomplete.",
    )
  }
  let scale = @bigint.BigInt::from_int(65536)
  let raw_forward = (@observation.time_ns(t2) - @observation.time_ns(t1)) *
    scale
  let raw_reverse = (@observation.time_ns(t4) - @observation.time_ns(t3)) *
    scale
  let sync_c = @bigint.BigInt::from_int64(hs.correction) +
    @bigint.BigInt::from_int64(hf.correction)
  let resp_c = @bigint.BigInt::from_int64(hr.correction)
  let forward = raw_forward - sync_c
  let reverse = raw_reverse - resp_c
  let expected = [
    forward - reverse,
    forward + reverse,
    forward,
    reverse,
    sync_c,
    resp_c,
  ]
  let actual = [
    measurement.offset_numerator,
    measurement.delay_numerator,
    measurement.forward_scaled,
    measurement.reverse_scaled,
    measurement.sync_correction_scaled,
    measurement.delay_correction_scaled,
  ]
  for i = 0; i < expected.length(); i = i + 1 {
    if decimal(actual[i], signed=true) != Some(expected[i]) {
      return failure(
        ids,
        @diagnostic.Violation,
        "Measurement integers contradict the reconstructed PTP timestamp and correction operands.",
      )
    }
  }
  if forward + reverse < @bigint.BigInt::from_int(0) {
    return failure(
      ids,
      @diagnostic.InsufficientEvidence,
      "Negative inferred mean path delay contradicts the accepted-measurement premise.",
    )
  }
  let ledger : CorrectionLedger = {
    uncorrected_offset_numerator: (raw_forward - raw_reverse).to_string(),
    uncorrected_delay_numerator: (raw_forward + raw_reverse).to_string(),
    corrected_offset_numerator: (forward - reverse).to_string(),
    corrected_delay_numerator: (forward + reverse).to_string(),
    denominator: 131072,
    forward_raw_scaled: raw_forward.to_string(),
    reverse_raw_scaled: raw_reverse.to_string(),
    contributions: [
      contribution(s, -1, true, "Sync.correctionField"),
      contribution(f, -1, true, "Follow_Up.correctionField"),
      contribution(r, 1, true, "Delay_Resp.correctionField"),
      contribution(q, 0, false, "Delay_Req.correctionField"),
    ],
  }
  match budget {
    Some(value) => assess(ledger, ids, value)
    None =>
      {
        frames: ids,
        status: @diagnostic.Pass,
        detail: "PTP operand ledger reconstructed exactly. Offset accuracy and deployment limit are not assessed without a caller-supplied error budget.",
        ledger: Some(ledger),
        assessment: None,
      }
  }
}
