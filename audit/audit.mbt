///|
pub(all) struct Report {
  findings : Array[@diagnostic.Finding]
  measurements : Array[@exchange.Measurement]
  input_fingerprint : String
  frames : Array[@exchange.Frame]
  context : @observation.Context
  assumptions : Json
  bmca_input : Json?
  metrology : Array[@metrology.Explanation]
}

///|
pub fn Report::status(self : Report) -> @diagnostic.Status {
  @diagnostic.summarize(self.findings)
}

///|
pub fn Report::exit_code(self : Report) -> Int32 {
  match self.status() {
    @diagnostic.Pass => 0
    @diagnostic.Violation => 1
    @diagnostic.InsufficientEvidence => 3
    @diagnostic.Unsupported => 4
  }
}

///|
pub fn Report::to_json(self : Report) -> Json {
  Json::object({
    "schema": Json::string("ptp-audit-report/v2"),
    "rule_set": Json::string("ptp-audit/0.3.0"),
    "scope": Json::string(
      "IEEE1588-2008 default multicast E2E two-step fixed-body subset; dataset preference only",
    ),
    "status": Json::string(self.status().label()),
    "exit_code": Json::number(self.exit_code().to_double()),
    "input_fingerprint": Json::string(self.input_fingerprint),
    "fingerprint_notice": Json::string(
      "FNV1a32 over UTF-16 code units; non-cryptographic, not an authenticity guarantee",
    ),
    "findings": Json::array(
      self.findings.map(fn(f) {
        @evidence.finding_json(
          f,
          self.frames,
          self.context,
          self.assumptions,
          self.bmca_input,
        )
      }),
    ),
    "measurements": Json::array(
      self.measurements.map(fn(m) { @evidence.measurement_json(m, self.frames) }),
    ),
    "metrology": Json::array(self.metrology.map(fn(e) { e.to_json() })),
    "coverage": @evidence.coverage_json(self.findings),
    "assumptions": self.assumptions,
    "not_checked": Json::array([
      Json::string(
        "Full IEEE compliance, clock accuracy, hardware/transport, qualification and port-state BMCA, unsupported profiles/TLVs, capture completeness",
      ),
    ]),
    "references": Json::array([
      Json::string("https://github.com/richardcochran/linuxptp/blob/v4.4/msg.h"),
      Json::string(
        "https://github.com/richardcochran/linuxptp/blob/v4.4/port.c",
      ),
      Json::string("https://github.com/richardcochran/linuxptp/blob/v4.4/bmc.c"),
      Json::string("research/wire-reference/verification.json"),
      Json::string("docs/rule-traceability.md"),
    ]),
  })
}

///|
priv suberror InputError {
  Invalid(String)
}

///|
fn object(
  v : Json,
  keys : Array[String],
  path : String,
) -> Map[String, Json] raise InputError {
  match v {
    Object(m) => {
      for k, _ in m {
        if !keys.contains(k) {
          raise Invalid(path + ": unknown field " + k)
        }
      }
      m
    }
    _ => raise Invalid(path + ": expected object")
  }
}

///|
fn required(m : Map[String, Json], key : String) -> Json raise InputError {
  match m.get(key) {
    Some(v) => v
    None => raise Invalid("missing field: " + key)
  }
}

///|
fn string(v : Json) -> String raise InputError {
  match v {
    String(s) =>
      if s.length() <= 4096 {
        s
      } else {
        raise Invalid("string exceeds 4096 characters")
      }
    _ => raise Invalid("expected string")
  }
}

///|
fn integer(v : Json) -> Int32 raise InputError {
  match v {
    Number(n, ..) =>
      if n >= 0.0 && n <= 2147483647.0 && n == n.to_int().to_double() {
        n.to_int()
      } else {
        raise Invalid("expected nonnegative Int32 integer")
      }
    _ => raise Invalid("expected integer number")
  }
}

///|
fn boolean(m : Map[String, Json], key : String) -> Bool raise InputError {
  match m.get(key) {
    None => false
    Some(True) => true
    Some(False) => false
    _ => raise Invalid(key + ": expected boolean")
  }
}

///|
fn array(v : Json, limit : Int32) -> Array[Json] raise InputError {
  match v {
    Array(a) =>
      if a.length() <= limit {
        a
      } else {
        raise Invalid("array exceeds limit " + limit.to_string())
      }
    _ => raise Invalid("expected array")
  }
}

///|
fn optional_array(
  m : Map[String, Json],
  key : String,
  limit : Int32,
) -> Array[Json] raise InputError {
  match m.get(key) {
    Some(v) => array(v, limit)
    None => []
  }
}

///|
fn port(v : Json) -> @wire.PortIdentity raise InputError {
  let m = object(v, ["clock", "port"], "port identity")
  let p : @wire.PortIdentity = {
    clock: string(required(m, "clock")),
    port: integer(required(m, "port")),
  }
  if !@wire.valid_port(p) {
    raise Invalid(
      "identity: 16 lowercase hex digits and port 1..65535 required",
    )
  }
  p
}

///|
fn timestamp(v : Json) -> @wire.PtpTimestamp raise InputError {
  let m = object(v, ["seconds", "nanos"], "timestamp")
  let s = string(required(m, "seconds"))
  if s == "" || s.length() > 15 {
    raise Invalid("seconds: unsigned 48-bit decimal string required")
  }
  let mut n = 0L
  for i = 0; i < s.length(); i = i + 1 {
    let c = s.code_unit_at(i).to_int() - 48
    if c < 0 || c > 9 {
      raise Invalid("seconds: decimal digits required")
    }
    n = n * 10 + c.to_int64()
    if n > 281474976710655L {
      raise Invalid("seconds exceeds 48 bits")
    }
  }
  let ns = integer(required(m, "nanos"))
  if ns >= 1_000_000_000 {
    raise Invalid("nanos must be below 1e9")
  }
  { seconds: n, nanos: ns, }
}

///|
fn fingerprint(text : String) -> String {
  let mut h = 2166136261U
  for i = 0; i < text.length(); i = i + 1 {
    h = (h ^ text.code_unit_at(i).to_uint()) * 16777619U
  }
  "fnv1a32-utf16:" + h.to_string()
}

///|
fn optional_budget(
  m : Map[String, Json],
  key : String,
) -> Int64? raise InputError {
  match m.get(key) {
    None => None
    Some(String(s)) => {
      if s == "" || s.length() > 19 {
        raise Invalid(key + ": unsigned Int64 decimal string required")
      }
      let mut n = 0L
      for i = 0; i < s.length(); i = i + 1 {
        let digit = s.code_unit_at(i).to_int() - 48
        if digit < 0 ||
          digit > 9 ||
          n > 922337203685477580L ||
          (n == 922337203685477580L && digit > 7) {
          raise Invalid(key + ": value exceeds nonnegative Int64 decimal range")
        }
        n = n * 10L + digit.to_int64()
      }
      Some(n)
    }
    Some(v) => Some(integer(v).to_int64())
  }
}

///|
fn parse_window(v : Json) -> @observation.Window raise InputError {
  let w = object(
    v,
    ["id", "epoch", "clock_domain", "start", "end", "complete"],
    "observation window",
  )
  @observation.Window::{
    id: string(required(w, "id")),
    epoch: integer(required(w, "epoch")),
    clock_domain: string(required(w, "clock_domain")),
    start: timestamp(required(w, "start")),
    end: timestamp(required(w, "end")),
    complete: boolean(w, "complete"),
  }
}

///|
fn parse_context(v : Json) -> @observation.Context raise InputError {
  let m = object(v, ["windows", "policy"], "observation")
  let windows = array(required(m, "windows"), 64).map(parse_window)
  let policy = match m.get("policy") {
    None => None
    Some(v) => {
      let p = object(
        v,
        ["source", "sync_follow_up_ns", "delay_response_ns"],
        "observation policy",
      )
      Some(@observation.Policy::{
        source: string(required(p, "source")),
        sync_follow_up_ns: optional_budget(p, "sync_follow_up_ns"),
        delay_response_ns: optional_budget(p, "delay_response_ns"),
      })
    }
  }
  @observation.Context::{ windows, policy, }
}

///|
fn parse_snapshot(
  b : Map[String, Json],
  frames : Array[@exchange.Frame],
  candidates : Array[@bmca.Candidate],
) -> @bmca.Snapshot raise InputError {
  let s = match b.get("snapshot") {
    Some(v) =>
      object(
        v,
        [
          "epoch", "window", "clock_domain", "decision_time", "announce_validity_ns",
          "validity_source", "validity_confirmed", "capture_window_confirmed",
        ],
        "bmca.snapshot",
      )
    None => Map([])
  }
  let samples = candidates.map(fn(c) {
    match @exchange.get_frame(frames, c.frame) {
      Some(f) => @exchange.sample(f)
      None =>
        @observation.Sample::{
          frame: c.frame,
          epoch: None,
          window: None,
          time: None,
          clock_domain: None,
        }
    }
  })
  let epoch = match s.get("epoch") {
    Some(v) => Some(integer(v))
    None => None
  }
  let window = match s.get("window") {
    Some(v) => Some(string(v))
    None => None
  }
  let domain = match s.get("clock_domain") {
    Some(v) => Some(string(v))
    None => None
  }
  let decision = match s.get("decision_time") {
    Some(v) => Some(timestamp(v))
    None => None
  }
  let validity = optional_budget(s, "announce_validity_ns")
  let source = match s.get("validity_source") {
    Some(v) => Some(string(v))
    None => None
  }
  @bmca.Snapshot::{
    epoch,
    window,
    clock_domain: domain,
    decision_time: decision,
    announce_validity_ns: validity,
    validity_source: source,
    validity_confirmed: boolean(s, "validity_confirmed"),
    capture_window_confirmed: boolean(s, "capture_window_confirmed"),
    samples,
  }
}

///|
fn parse_error_budget(v : Json) -> @metrology.ErrorBudget raise InputError {
  let b = object(
    v,
    [
      "timestamp_error_bounds_scaled", "correction_error_bound_scaled", "path_asymmetry_bound_scaled",
      "offset_limit_scaled", "source", "assumptions", "relative_rate_bound_confirmed",
    ],
    "error_budget",
  )
  // Values remain decimal strings all the way into the exact MoonBit algebra.
  // Missing provenance is evidence insufficiency, never an implied calibration.
  @metrology.ErrorBudget::{
    timestamp_error_bounds_scaled: array(
      required(b, "timestamp_error_bounds_scaled"),
      4,
    ).map(string),
    correction_error_bound_scaled: string(
      required(b, "correction_error_bound_scaled"),
    ),
    path_asymmetry_bound_scaled: string(
      required(b, "path_asymmetry_bound_scaled"),
    ),
    offset_limit_scaled: string(required(b, "offset_limit_scaled")),
    source: match b.get("source") {
      Some(v) => string(v)
      None => ""
    },
    assumptions: match b.get("assumptions") {
      Some(v) => string(v)
      None => ""
    },
    relative_rate_bound_confirmed: boolean(b, "relative_rate_bound_confirmed"),
  }
}

///|
fn parse_case(text : String, id : String) -> Report raise {
  let value = @json.parse(
    text,
    reject_duplicate_keys=true,
    max_nesting_depth=32,
  )
  let m = object(
    value,
    [
      "schema", "profile", "frames", "pair_claims", "exchanges", "assumptions", "observation",
      "bmca", "error_budget",
    ],
    "case",
  )
  let schema = string(required(m, "schema"))
  let profile = string(required(m, "profile"))
  if schema != "ptp-audit/v1" || profile != "default-e2e-two-step-2008" {
    return {
      findings: [
        @diagnostic.finding(
          "SCOPE.CASE",
          @diagnostic.Unsupported,
          [],
          None,
          "ptp-audit/v1; default-e2e-two-step-2008",
          schema + "; " + profile,
          "No rules executed outside the declared scope.",
        ),
      ],
      measurements: [],
      input_fingerprint: id,
      frames: [],
      context: @observation.Context::{ windows: [], policy: None, },
      assumptions: Json::object({}),
      bmca_input: None,
      metrology: [],
    }
  }
  let findings = []
  let frames : Array[@exchange.Frame] = []
  let ids : Array[Int32] = []
  for v in array(required(m, "frames"), 256) {
    let f = object(
      v,
      [
        "id", "epoch", "payload_hex", "local_port", "event_time", "clock_domain",
        "direction", "window", "capture_time", "capture_clock_domain",
      ],
      "frame",
    )
    let frame_id = integer(required(f, "id"))
    if ids.contains(frame_id) {
      raise Invalid("duplicate frame id: " + frame_id.to_string())
    }
    ids.push(frame_id)
    let epoch = match f.get("epoch") {
      Some(v) => Some(integer(v))
      None => None
    }
    let lp = match f.get("local_port") {
      Some(v) => Some(port(v))
      None => None
    }
    let time = match f.get("event_time") {
      Some(v) => Some(timestamp(v))
      None => None
    }
    let domain = match f.get("clock_domain") {
      Some(v) => Some(string(v))
      None => None
    }
    let direction = match f.get("direction") {
      Some(v) => {
        let d = string(v)
        if d != "rx" && d != "tx" {
          raise Invalid("direction must be rx or tx")
        }
        Some(d)
      }
      None => None
    }
    let window = match f.get("window") {
      Some(v) => Some(string(v))
      None => None
    }
    let capture_time = match f.get("capture_time") {
      Some(v) => Some(timestamp(v))
      None => None
    }
    let capture_clock_domain = match f.get("capture_clock_domain") {
      Some(v) => Some(string(v))
      None => None
    }
    let hex = string(required(f, "payload_hex"))
    let decoded = match @wire.from_hex(hex) {
      Ok(b) => @wire.decode(b)
      Err(e) => Err(e)
    }
    match decoded {
      Ok(p) => {
        findings.push(
          @diagnostic.finding(
            "WIRE.FIXED_BODY",
            @diagnostic.Pass,
            [frame_id],
            None,
            "supported fixed message layout",
            "decoded",
            "Only implemented wire rules checked; not full IEEE certification.",
          ),
        )
        frames.push({
          id: frame_id,
          epoch,
          packet: p,
          local_port: lp,
          event_time: time,
          clock_domain: domain,
          direction,
          window,
          capture_time,
          capture_clock_domain,
        })
      }
      Err(e) =>
        findings.push(
          @diagnostic.finding(
            e.code,
            e.status,
            [frame_id],
            Some(e.offset),
            e.expected,
            e.actual,
            "Payload not admitted to exchange or BMCA checking.",
          ),
        )
    }
  }
  let pairs = optional_array(m, "pair_claims", 256).map(fn(v) raise {
    let p = object(v, ["sync", "follow_up"], "pair claim")
    @exchange.PairClaim::{
      sync: integer(required(p, "sync")),
      follow_up: integer(required(p, "follow_up")),
    }
  })
  let exchanges = optional_array(m, "exchanges", 256).map(fn(v) raise {
    let p = object(
      v,
      ["sync", "follow_up", "delay_req", "delay_resp"],
      "exchange claim",
    )
    @exchange.ExchangeClaim::{
      sync: integer(required(p, "sync")),
      follow_up: integer(required(p, "follow_up")),
      delay_req: integer(required(p, "delay_req")),
      delay_resp: integer(required(p, "delay_resp")),
    }
  })
  let assumptions = match m.get("assumptions") {
    Some(v) =>
      object(
        v,
        ["symmetric_path", "timestamp_provenance", "stable_rates"],
        "assumptions",
      )
    None => Map([])
  }
  let context = match m.get("observation") {
    Some(v) => parse_context(v)
    None => @observation.Context::{ windows: [], policy: None, }
  }
  // Validate all declared fields even if this batch contains only Announce.
  let symmetric = boolean(assumptions, "symmetric_path")
  let provenance = boolean(assumptions, "timestamp_provenance")
  let rates = boolean(assumptions, "stable_rates")
  let error_budget = match m.get("error_budget") {
    Some(v) => Some(parse_error_budget(v))
    None => None
  }
  let er = if frames.any(fn(f) { f.packet.header.kind != @wire.Announce }) ||
    !pairs.is_empty() ||
    !exchanges.is_empty() {
    @exchange.audit(
      frames, pairs, exchanges, symmetric, provenance, rates, context,
    )
  } else {
    @exchange.Report::{ findings: [], measurements: [], }
  }
  for f in er.findings {
    findings.push(f)
  }
  let bmca_input = m.get("bmca")
  match m.get("bmca") {
    Some(v) => {
      let b = object(
        v,
        [
          "candidates", "selected", "candidates_complete", "eligibility_confirmed",
          "snapshot",
        ],
        "bmca",
      )
      let candidates = []
      let mut present = true
      for v in array(required(b, "candidates"), 64) {
        let c = object(v, ["id", "frame", "receiver"], "candidate")
        let cid = string(required(c, "id"))
        if cid == "" {
          raise Invalid("empty candidate id")
        }
        let fid = integer(required(c, "frame"))
        let receiver = port(required(c, "receiver"))
        match @exchange.get_frame(frames, fid) {
          Some(f) =>
            match f.packet.body {
              @wire.Announcement(data) =>
                candidates.push(@bmca.Candidate::{
                  id: cid,
                  frame: fid,
                  domain: f.packet.header.domain,
                  data,
                  sender: f.packet.header.source,
                  receiver,
                })
              _ => raise Invalid("BMCA candidate must reference an Announce")
            }
          None => {
            present = false
            findings.push(
              @diagnostic.finding(
                "BMCA.MISSING_FRAME",
                @diagnostic.InsufficientEvidence,
                [fid],
                None,
                "decodable Announce frame",
                "missing or inadmissible",
                "No preference inferred from a partial candidate set.",
              ),
            )
          }
        }
      }
      let selected = match b.get("selected") {
        Some(v) => Some(string(v))
        None => None
      }
      let snapshot = parse_snapshot(b, frames, candidates)
      for
        f in @bmca.audit(
          candidates,
          selected,
          boolean(b, "candidates_complete") && present,
          boolean(b, "eligibility_confirmed"),
          context,
          snapshot,
        ) {
        findings.push(f)
      }
    }
    None =>
      if er.findings.is_empty() {
        findings.push(
          @diagnostic.finding(
            "SCOPE.NO_SEMANTIC_CHECK",
            @diagnostic.InsufficientEvidence,
            [],
            None,
            "exchange observations or a BMCA snapshot",
            "no semantic input",
            "Wire decoding alone is not a complete protocol verdict.",
          ),
        )
      }
  }
  let metrology = er.measurements.map(fn(measurement) {
    let explanation = @metrology.explain(measurement, frames, error_budget)
    findings.push(
      @diagnostic.finding(
        if error_budget is Some(_) {
          "METROLOGY.ERROR_BUDGET"
        } else {
          "METROLOGY.LEDGER"
        },
        explanation.status,
        measurement.frames,
        None,
        "exact PTP operand ledger and, when supplied, a supported conditional error budget",
        explanation.detail,
        "The assessment verdict is separate from protocol status. within_limit/outside_limit/indeterminate is conditional on caller-supplied bounds; see the metrology entry for exact values.",
      ),
    )
    explanation
  })
  if error_budget is Some(_) && er.measurements.is_empty() {
    findings.push(
      @diagnostic.finding(
        "METROLOGY.ERROR_BUDGET",
        @diagnostic.InsufficientEvidence,
        [],
        None,
        "at least one admitted four-frame measurement",
        "no admitted measurement",
        "No timing-limit assessment is emitted from rejected or incomplete exchange evidence.",
      ),
    )
  }
  {
    findings,
    measurements: er.measurements,
    input_fingerprint: id,
    frames,
    context,
    assumptions: Json::object(assumptions),
    bmca_input,
    metrology,
  }
}

///|
pub fn audit(text : String) -> Report {
  let id = fingerprint(text)
  if text.length() > 1_048_576 {
    return {
      findings: [
        @diagnostic.finding(
          "INPUT.RESOURCE",
          @diagnostic.Unsupported,
          [],
          None,
          "at most 1048576 UTF-16 units",
          text.length().to_string(),
          "Input budget exceeded.",
        ),
      ],
      measurements: [],
      input_fingerprint: id,
      frames: [],
      context: @observation.Context::{ windows: [], policy: None, },
      assumptions: Json::object({}),
      bmca_input: None,
      metrology: [],
    }
  }
  parse_case(text, id) catch {
    e =>
      {
        findings: [
          @diagnostic.finding(
            "INPUT.SCHEMA",
            @diagnostic.Violation,
            [],
            None,
            "strict ptp-audit/v1 case",
            match e {
              Invalid(m) => m
              _ => "input validation failed"
            },
            "Input validation failed; no partial success report emitted.",
          ),
        ],
        measurements: [],
        input_fingerprint: id,
        frames: [],
        context: @observation.Context::{ windows: [], policy: None, },
        assumptions: Json::object({}),
        bmca_input: None,
        metrology: [],
      }
  }
}

///|
pub fn audit_json(text : String) -> String {
  audit(text).to_json().stringify(indent=2)
}
