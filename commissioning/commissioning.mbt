///|
/// A selected upstream port is deliberately distinct from its grandmaster.
pub(all) struct Selection {
  candidate : String
  announce_frame : Int32
  sender : @wire.PortIdentity
  receiver : @wire.PortIdentity
  grandmaster : String
  domain : Int32
  epoch : Int32
  window : String
  capture_clock : String
  announce_time : @wire.PtpTimestamp
  decision_time : @wire.PtpTimestamp
  announce_expiry_ns : String
  announce_validity_ns : Int64
  stability_source : String
  stability_until : @wire.PtpTimestamp
}

///|
pub(all) struct Binding {
  frames : Array[Int32]
  findings : Array[@diagnostic.Finding]
  evidence : Json
}

///|
pub(all) struct Step {
  id : String
  case_report : @audit.Report
  selection : Selection?
  bindings : Array[Binding]
  findings : Array[@diagnostic.Finding]
  capture_start : @wire.PtpTimestamp?
  capture_end : @wire.PtpTimestamp?
}

///|
pub(all) struct Transition {
  from_step : String
  to_step : String
  finding : @diagnostic.Finding
  classification : String?
  evidence : Json
}

///|
/// Campaign-wide premise consistency is separate from adjacent transitions.
pub(all) struct StabilityConflict {
  from_step : String
  to_step : String
  finding : @diagnostic.Finding
  evidence : Json
}

///|
pub(all) struct Report {
  steps : Array[Step]
  transitions : Array[Transition]
  selection_conflicts : Array[StabilityConflict]
  findings : Array[@diagnostic.Finding]
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
fn timing_verdict(report : @audit.Report) -> String {
  let verdicts = report.metrology.filter_map(fn(e) {
    match e.assessment {
      Some(a) => Some(a.verdict)
      None => None
    }
  })
  if verdicts.contains("outside_limit") {
    return "outside_limit"
  }
  if verdicts.contains("indeterminate") {
    return "indeterminate"
  }
  if !report.measurements.is_empty() &&
    verdicts.length() == report.measurements.length() &&
    verdicts.all(fn(v) { v == "within_limit" }) {
    return "within_limit"
  }
  "unassessed"
}

///|
/// Protocol consistency and meeting an operator's timing limit are distinct.
pub fn Report::operational_acceptance(self : Report) -> String {
  if self.status() != @diagnostic.Pass {
    return "evidence_not_accepted"
  }
  let verdicts = self.steps.map(fn(s) { timing_verdict(s.case_report) })
  if verdicts.contains("outside_limit") {
    return "outside_limit"
  }
  if verdicts.contains("indeterminate") {
    return "indeterminate"
  }
  if !verdicts.is_empty() && verdicts.all(fn(v) { v == "within_limit" }) {
    return "within_limit"
  }
  "unassessed"
}

///|
fn stamp(value : @wire.PtpTimestamp) -> Json {
  Json::object({
    "seconds": Json::string(value.seconds.to_string()),
    "nanos": Json::number(value.nanos.to_double()),
  })
}

///|
fn identity(value : @wire.PortIdentity) -> Json {
  Json::object({
    "clock": Json::string(value.clock),
    "port": Json::number(value.port.to_double()),
  })
}

///|
fn optional_stamp(value : @wire.PtpTimestamp?) -> Json {
  match value {
    Some(t) => stamp(t)
    None => Json::null()
  }
}

///|
fn selection_json(value : Selection) -> Json {
  Json::object({
    "candidate": Json::string(value.candidate),
    "announce_frame": Json::number(value.announce_frame.to_double()),
    "upstream_sender": identity(value.sender),
    "receiver": identity(value.receiver),
    "grandmaster": Json::string(value.grandmaster),
    "domain": Json::number(value.domain.to_double()),
    "epoch": Json::number(value.epoch.to_double()),
    "window": Json::string(value.window),
    "capture_clock": Json::string(value.capture_clock),
    "announce_time": stamp(value.announce_time),
    "decision_time": stamp(value.decision_time),
    "announce_expiry_ns": Json::string(value.announce_expiry_ns),
    "announce_validity_ns": Json::string(value.announce_validity_ns.to_string()),
    "selection_stability": Json::object({
      "source": Json::string(value.stability_source),
      "confirmed": Json::boolean(true),
      "until": stamp(value.stability_until),
      "meaning": Json::string(
        "Caller confirms this selected upstream sender and advertised grandmaster remained unchanged for this receiver/domain throughout the closed interval [decision_time, until].",
      ),
    }),
  })
}

///|
fn scoped_finding(value : @diagnostic.Finding, step_id : String) -> Json {
  match value.to_json() {
    Object(m) => {
      m.set("step_id", Json::string(step_id))
      Json::object(m)
    }
    other => other
  }
}

///|
fn transition_finding(value : Transition) -> Json {
  match value.finding.to_json() {
    Object(m) => {
      m.set("from_step", Json::string(value.from_step))
      m.set("to_step", Json::string(value.to_step))
      Json::object(m)
    }
    other => other
  }
}

///|
fn conflict_finding(value : StabilityConflict) -> Json {
  match value.finding.to_json() {
    Object(m) => {
      m.set("from_step", Json::string(value.from_step))
      m.set("to_step", Json::string(value.to_step))
      Json::object(m)
    }
    other => other
  }
}

///|
pub fn Report::to_json(self : Report) -> Json {
  let all_findings = []
  if self.steps.is_empty() {
    for f in self.findings {
      all_findings.push(scoped_finding(f, "campaign"))
    }
  } else {
    for s in self.steps {
      for f in s.findings {
        all_findings.push(scoped_finding(f, s.id))
      }
    }
    for t in self.transitions {
      all_findings.push(transition_finding(t))
    }
    for conflict in self.selection_conflicts {
      all_findings.push(conflict_finding(conflict))
    }
  }
  Json::object({
    "schema": Json::string("ptp-commission-report/v1"),
    "status": Json::string(self.status().label()),
    "exit_code": Json::number(self.exit_code().to_double()),
    "operational_acceptance": Json::string(self.operational_acceptance()),
    "timing_limit_notice": Json::string(
      "Pass records consistent protocol evidence; it does not accept an operator timing limit. Consult operational_acceptance and each raw case metrology assessment.",
    ),
    "timing_limit_verdicts": Json::array(
      self.steps.map(fn(s) {
        Json::object({
          "step_id": Json::string(s.id),
          "verdict": Json::string(timing_verdict(s.case_report)),
          "binding_evidence_status": Json::string(
            @diagnostic.summarize(s.findings).label(),
          ),
        })
      }),
    ),
    "scope": Json::string(
      "Offline PTP selected-Announce to explicit E2E quartet binding and adjacent observed upstream identity comparison",
    ),
    "findings": Json::array(all_findings),
    "steps": Json::array(
      self.steps.map(fn(s) {
        Json::object({
          "id": Json::string(s.id),
          "status": Json::string(@diagnostic.summarize(s.findings).label()),
          "case_report": s.case_report.to_json(),
          "selection": match s.selection {
            Some(v) => selection_json(v)
            None => Json::null()
          },
          "capture_interval": Json::object({
            "start": optional_stamp(s.capture_start),
            "end": optional_stamp(s.capture_end),
          }),
          "findings": Json::array(
            s.findings.map(fn(f) { scoped_finding(f, s.id) }),
          ),
          "bindings": Json::array(
            s.bindings.map(fn(b) {
              Json::object({
                "step_id": Json::string(s.id),
                "frames": Json::array(
                  b.frames.map(fn(n) { Json::number(n.to_double()) }),
                ),
                "accepted": Json::boolean(
                  @diagnostic.summarize(b.findings) == @diagnostic.Pass,
                ),
                "findings": Json::array(
                  b.findings.map(fn(f) { scoped_finding(f, s.id) }),
                ),
                "evidence": b.evidence,
              })
            }),
          ),
        })
      }),
    ),
    "transitions": Json::array(
      self.transitions.map(fn(t) {
        Json::object({
          "from_step": Json::string(t.from_step),
          "to_step": Json::string(t.to_step),
          "status": Json::string(t.finding.status.label()),
          "classification": match t.classification {
            Some(s) => Json::string(s)
            None => Json::null()
          },
          "finding": transition_finding(t),
          "evidence": t.evidence,
        })
      }),
    ),
    "selection_conflicts": Json::array(
      self.selection_conflicts.map(fn(c) {
        Json::object({
          "from_step": Json::string(c.from_step),
          "to_step": Json::string(c.to_step),
          "finding": conflict_finding(c),
          "evidence": c.evidence,
        })
      }),
    ),
    "limitations": Json::array([
      Json::string(
        "Selection stability asserts the selected Announce-derived sender AND advertised grandmaster identities remained unchanged on this receiver/domain over [decision_time, until]. Selection stability, capture-clock continuity, candidate completeness and qualification are caller-supplied assertions; packet bytes do not independently prove them.",
      ),
      Json::string(
        "A binding confirms consistency of a bounded offline evidence set, not device port-state execution, servo convergence or absolute clock accuracy.",
      ),
      Json::string(
        "Identity transitions compare only adjacent fully accepted steps with the same receiver/domain and confirmed continuous capture clock; rejected steps are never bridged. Selection-stability assertions are separately checked for contradictions across every accepted step pair, including nonadjacent pairs.",
      ),
      Json::string(
        "Observed identity changes do not measure failover duration, packet loss, synchronization recovery or a switch instant.",
      ),
      Json::string(
        "Offsets remain attached to each raw case report; offsets across masters are never subtracted, and path asymmetry or common PTP timescale is not inferred.",
      ),
      Json::string(
        "No complete IEEE 1588 conformance certification, full BMCA qualification, port-state machine or hardware/transport validation is performed.",
      ),
    ]),
  })
}

///|
priv suberror InputError {
  Invalid(String)
}

///|
fn fields(
  value : Json,
  allowed : Array[String],
  path : String,
) -> Map[String, Json] raise InputError {
  match value {
    Object(m) => {
      for key, _ in m {
        if !allowed.contains(key) {
          raise Invalid(path + ": unknown field " + key)
        }
      }
      m
    }
    _ => raise Invalid(path + ": expected object")
  }
}

///|
fn need(m : Map[String, Json], name : String) -> Json raise InputError {
  match m.get(name) {
    Some(v) => v
    None => raise Invalid("missing " + name)
  }
}

///|
fn text(value : Json) -> String raise InputError {
  match value {
    String(s) if s.length() <= 4096 => s
    _ => raise Invalid("expected string of at most 4096 UTF-16 units")
  }
}

///|
fn natural(value : Json) -> Int32 raise InputError {
  match value {
    Number(n, ..) if n >= 0.0 &&
      n <= 2147483647.0 &&
      n == n.to_int().to_double() => n.to_int()
    _ => raise Invalid("expected nonnegative Int32 integer")
  }
}

///|
fn flag(m : Map[String, Json], key : String) -> Bool raise InputError {
  match m.get(key) {
    None | Some(False) => false
    Some(True) => true
    _ => raise Invalid(key + ": expected boolean")
  }
}

///|
fn time(value : Json) -> @wire.PtpTimestamp raise InputError {
  let m = fields(value, ["seconds", "nanos"], "timestamp")
  let s = text(need(m, "seconds"))
  if s.length() == 0 || s.length() > 15 {
    raise Invalid("invalid timestamp seconds")
  }
  let mut seconds = 0L
  for i = 0; i < s.length(); i = i + 1 {
    let digit = s.code_unit_at(i).to_int() - 48
    if digit < 0 || digit > 9 {
      raise Invalid("timestamp seconds must be decimal")
    }
    seconds = seconds * 10L + digit.to_int64()
    if seconds > 281474976710655L {
      raise Invalid("timestamp seconds exceeds 48 bits")
    }
  }
  let nanos = natural(need(m, "nanos"))
  let t : @wire.PtpTimestamp = { seconds, nanos, }
  if !@wire.valid_time(t) {
    raise Invalid("timestamp nanos must be below 1e9")
  }
  t
}

///|
fn budget(value : Json) -> Int64 raise InputError {
  match value {
    Number(_, ..) => natural(value).to_int64()
    String(s) => {
      if s.length() == 0 || s.length() > 19 {
        raise Invalid("invalid validity budget")
      }
      let mut n = 0L
      for i = 0; i < s.length(); i = i + 1 {
        let d = s.code_unit_at(i).to_int() - 48
        if d < 0 ||
          d > 9 ||
          n > 922337203685477580L ||
          (n == 922337203685477580L && d > 7) {
          raise Invalid("validity budget exceeds Int64")
        }
        n = n * 10L + d.to_int64()
      }
      n
    }
    _ => raise Invalid("invalid validity budget")
  }
}

///|
fn port(value : Json) -> @wire.PortIdentity raise InputError {
  let m = fields(value, ["clock", "port"], "port identity")
  let p : @wire.PortIdentity = {
    clock: text(need(m, "clock")),
    port: natural(need(m, "port")),
  }
  if !@wire.valid_port(p) {
    raise Invalid("invalid port identity")
  }
  p
}

///|
fn note(
  id : String,
  rule : String,
  status : @diagnostic.Status,
  frames : Array[Int32],
  expected : String,
  actual : String,
  detail : String,
) -> @diagnostic.Finding {
  @diagnostic.finding(
    rule,
    status,
    frames,
    None,
    expected,
    actual,
    "step=" + id + "; " + detail,
  )
}

///|
fn resolve(
  id : String,
  report : @audit.Report,
  stability : Json?,
  findings : Array[@diagnostic.Finding],
) -> Selection? raise InputError {
  let stable = match stability {
    Some(v) =>
      fields(v, ["source", "confirmed", "until"], "selection_stability")
    None => Map([])
  }
  let source = match stable.get("source") {
    Some(v) => text(v)
    None => ""
  }
  let confirmed = flag(stable, "confirmed")
  let until = match stable.get("until") {
    Some(v) => Some(time(v))
    None => None
  }
  if !confirmed || !@observation.text_ok(source, 1024) || until is None {
    findings.push(
      note(
        id,
        "COMMISSION.STABILITY.EVIDENCE",
        @diagnostic.InsufficientEvidence,
        [],
        "confirmed selection stability with nonblank source and until",
        "missing or unconfirmed",
        "A BMCA snapshot alone does not establish that its selected upstream remained selected during an exchange.",
      ),
    )
    return None
  }
  let b = match report.bmca_input {
    Some(Object(m)) => m
    _ => {
      findings.push(
        note(
          id,
          "COMMISSION.SELECTION.EVIDENCE",
          @diagnostic.InsufficientEvidence,
          [],
          "a passing BMCA snapshot with explicit selected candidate",
          "missing BMCA input",
          "No selected master is inferred from Sync or Delay_Req.",
        ),
      )
      return None
    }
  }
  let selected = match b.get("selected") {
    Some(String(s)) => s
    _ => {
      findings.push(
        note(
          id,
          "COMMISSION.SELECTION.EVIDENCE",
          @diagnostic.InsufficientEvidence,
          [],
          "explicit selected candidate",
          "missing selected",
          "Dataset ordering alone is not an observed selection declaration.",
        ),
      )
      return None
    }
  }
  let candidates = match b.get("candidates") {
    Some(Array(a)) => a
    _ => []
  }
  let mut candidate = None
  for c in candidates {
    match c {
      Object(m) if m.get("id") == Some(Json::string(selected)) =>
        candidate = Some(m)
      _ => ()
    }
  }
  let c = match candidate {
    Some(m) => m
    None => return None
  }
  let frame_id = natural(need(c, "frame"))
  let announce = match @exchange.get_frame(report.frames, frame_id) {
    Some(f) => f
    None => return None
  }
  let data = match announce.packet.body {
    @wire.Announcement(a) => a
    _ => return None
  }
  let snap = match b.get("snapshot") {
    Some(Object(m)) => m
    _ => return None
  }
  let epoch = natural(need(snap, "epoch"))
  let window_id = text(need(snap, "window"))
  let capture_clock = text(need(snap, "clock_domain"))
  let decision_time = time(need(snap, "decision_time"))
  let validity = budget(need(snap, "announce_validity_ns"))
  let announce_time = match announce.capture_time {
    Some(t) => t
    None => return None
  }
  let until = match until {
    Some(t) => t
    None => return None
  }
  let window = match @observation.get_window(report.context, window_id) {
    Some(w) => w
    None => return None
  }
  if @observation.time_ns(until) < @observation.time_ns(decision_time) ||
    @observation.time_ns(until) < @observation.time_ns(window.start) ||
    @observation.time_ns(until) > @observation.time_ns(window.end) {
    findings.push(
      note(
        id,
        "COMMISSION.STABILITY.WINDOW",
        @diagnostic.Violation,
        [frame_id],
        "decision <= stability.until within the snapshot observation window",
        "until=" +
        @observation.time_ns(until).to_string() +
        "; decision=" +
        @observation.time_ns(decision_time).to_string() +
        "; window=" +
        @observation.time_ns(window.start).to_string() +
        ".." +
        @observation.time_ns(window.end).to_string(),
        "Confirmed stability contradicts its declared effective observation interval.",
      ),
    )
    return None
  }
  Some({
    candidate: selected,
    announce_frame: frame_id,
    sender: announce.packet.header.source,
    receiver: port(need(c, "receiver")),
    grandmaster: data.grandmaster,
    domain: announce.packet.header.domain,
    epoch,
    window: window_id,
    capture_clock,
    announce_time,
    decision_time,
    announce_expiry_ns: (@observation.time_ns(announce_time) +
    @bigint.BigInt::from_int64(validity)).to_string(),
    announce_validity_ns: validity,
    stability_source: source,
    stability_until: until,
  })
}

///|
fn bind(
  id : String,
  measurement : @exchange.Measurement,
  report : @audit.Report,
  selected : Selection,
) -> Binding {
  let frames = measurement.frames.map(fn(n) {
    @exchange.get_frame(report.frames, n)
  })
  let findings = []
  let evidence = Json::object({
    "selected_announce": selection_json(selected),
    "measurement": Json::object({
      "offset_numerator": Json::string(measurement.offset_numerator),
      "delay_numerator": Json::string(measurement.delay_numerator),
      "denominator": Json::number(measurement.denominator.to_double()),
    }),
    "quartet": Json::array(
      frames.map(fn(f) {
        match f {
          Some(v) =>
            Json::object({
              "frame": Json::number(v.id.to_double()),
              "source": identity(v.packet.header.source),
              "domain": Json::number(v.packet.header.domain.to_double()),
              "local_port": match v.local_port {
                Some(p) => identity(p)
                None => Json::null()
              },
              "epoch": match v.epoch {
                Some(n) => Json::number(n.to_double())
                None => Json::null()
              },
              "window": match v.window {
                Some(s) => Json::string(s)
                None => Json::null()
              },
              "capture_clock": match v.capture_clock_domain {
                Some(s) => Json::string(s)
                None => Json::null()
              },
              "capture_time": optional_stamp(v.capture_time),
            })
          None => Json::null()
        }
      }),
    ),
  })
  if frames.length() != 4 || frames.any(fn(f) { f is None }) {
    findings.push(
      note(
        id,
        "COMMISSION.BINDING.EVIDENCE",
        @diagnostic.InsufficientEvidence,
        measurement.frames,
        "four decoded measurement frames",
        "missing quartet frame",
        "No binding inferred from partial evidence.",
      ),
    )
    return { frames: measurement.frames, findings, evidence, }
  }
  let concrete = frames.filter_map(fn(f) { f })
  let identity_ok = concrete[0].packet.header.source == selected.sender &&
    concrete[1].packet.header.source == selected.sender &&
    concrete[3].packet.header.source == selected.sender &&
    concrete[2].packet.header.source == selected.receiver &&
    concrete[0].local_port == Some(selected.receiver) &&
    concrete[2].local_port == Some(selected.receiver)
  if !identity_ok {
    findings.push(
      note(
        id,
        "COMMISSION.BINDING.IDENTITY",
        @diagnostic.Violation,
        measurement.frames,
        "Sync/Follow_Up/Delay_Resp source=" +
        selected.sender.label() +
        "; Delay_Req source and local receiver=" +
        selected.receiver.label(),
        "quartet sources=" +
        concrete.map(fn(f) { f.packet.header.source.label() }).join(","),
        "A valid E2E exchange can still belong to a different upstream than the BMCA selection; raw arithmetic is retained but this binding is rejected.",
      ),
    )
  }
  let context_ok = concrete.all(fn(f) {
    f.packet.header.domain == selected.domain &&
    f.epoch == Some(selected.epoch) &&
    f.window == Some(selected.window) &&
    f.capture_clock_domain == Some(selected.capture_clock)
  })
  if !context_ok {
    findings.push(
      note(
        id,
        "COMMISSION.BINDING.CONTEXT",
        @diagnostic.Violation,
        measurement.frames,
        "all quartet frames in selected Announce domain/epoch/window/capture clock",
        "quartet context differs from selected snapshot",
        "PTP identities cannot be joined across unrelated observation contexts.",
      ),
    )
  }
  let expiry = @observation.time_ns(selected.announce_time) +
    @bigint.BigInt::from_int64(selected.announce_validity_ns)
  for f in concrete {
    match f.capture_time {
      None =>
        findings.push(
          note(
            id,
            "COMMISSION.BINDING.EVIDENCE",
            @diagnostic.InsufficientEvidence,
            [f.id],
            "capture time for every quartet frame",
            "missing capture time",
            "Event timestamps do not substitute for capture chronology.",
          ),
        )
      Some(t) => {
        let n = @observation.time_ns(t)
        if n < @observation.time_ns(selected.decision_time) ||
          n > @observation.time_ns(selected.stability_until) ||
          n > expiry {
          findings.push(
            note(
              id,
              "COMMISSION.BINDING.VALIDITY",
              @diagnostic.Violation,
              [f.id, selected.announce_frame],
              "decision <= quartet capture <= min(stability.until, selected Announce capture + validity)",
              "capture=" +
              n.to_string() +
              "; decision=" +
              @observation.time_ns(selected.decision_time).to_string() +
              "; stability.until=" +
              @observation.time_ns(selected.stability_until).to_string() +
              "; announce_expiry=" +
              expiry.to_string(),
              "Confirmed selection and validity premises do not cover this exchange frame.",
            ),
          )
        }
      }
    }
  }
  if findings.is_empty() {
    findings.push(
      note(
        id,
        "COMMISSION.BINDING.ACCEPTED",
        @diagnostic.Pass,
        measurement.frames,
        "selected Announce sender/receiver/domain and current snapshot cover the full E2E quartet",
        "upstream=" +
        selected.sender.label() +
        "; receiver=" +
        selected.receiver.label() +
        "; grandmaster=" +
        selected.grandmaster,
        "Conditionally bound to the caller-confirmed selected upstream interval; this does not establish servo convergence.",
      ),
    )
  }
  { frames: measurement.frames, findings, evidence, }
}

///|
fn check_step(value : Json) -> Step raise InputError {
  let m = fields(value, ["id", "case", "selection_stability"], "step")
  let id = text(need(m, "id"))
  if !@observation.text_ok(id, 128) {
    raise Invalid("step id must be nonblank and at most 128 characters")
  }
  let case_report = @audit.audit(need(m, "case").stringify())
  let findings = [
    note(
      id,
      "COMMISSION.CASE",
      case_report.status(),
      [],
      "embedded case status Pass",
      case_report.status().label(),
      "The complete raw case report is retained exactly once for this step.",
    ),
  ]
  let bindings = []
  let mut selection = None
  let mut capture_start = None
  let mut capture_end = None
  // Validate stability shape even when the embedded case is rejected.
  match m.get("selection_stability") {
    Some(v) => {
      let s = fields(v, ["source", "confirmed", "until"], "selection_stability")
      match s.get("source") {
        Some(v) => {
          let _ = text(v)
        }
        None => ()
      }
      let _ = flag(s, "confirmed")
      match s.get("until") {
        Some(v) => {
          let _ = time(v)
        }
        None => ()
      }
    }
    None => ()
  }
  if case_report.status() == @diagnostic.Pass {
    selection = resolve(id, case_report, m.get("selection_stability"), findings)
    match selection {
      Some(s) => {
        if case_report.measurements.is_empty() {
          findings.push(
            note(
              id,
              "COMMISSION.BINDING.EVIDENCE",
              @diagnostic.InsufficientEvidence,
              [],
              "at least one accepted E2E quartet measurement",
              "no measurement",
              "An Announce-only snapshot cannot demonstrate that an exchange used its selected upstream.",
            ),
          )
        }
        for measurement in case_report.measurements {
          let binding = bind(id, measurement, case_report, s)
          for f in binding.findings {
            findings.push(f)
          }
          if @diagnostic.summarize(binding.findings) == @diagnostic.Pass {
            for fid in binding.frames {
              match @exchange.get_frame(case_report.frames, fid) {
                Some({ capture_time: Some(t), .. }) => {
                  match capture_start {
                    None => capture_start = Some(t)
                    Some(old) =>
                      if @observation.time_ns(t) < @observation.time_ns(old) {
                        capture_start = Some(t)
                      }
                  }
                  match capture_end {
                    None => capture_end = Some(t)
                    Some(old) =>
                      if @observation.time_ns(t) > @observation.time_ns(old) {
                        capture_end = Some(t)
                      }
                  }
                }
                _ => ()
              }
            }
          }
          bindings.push(binding)
        }
      }
      None =>
        if @diagnostic.summarize(findings) == @diagnostic.Pass {
          findings.push(
            note(
              id,
              "COMMISSION.SELECTION.EVIDENCE",
              @diagnostic.InsufficientEvidence,
              [],
              "resolvable selected Announce and complete snapshot metadata",
              "selected snapshot unavailable",
              "No partial upstream binding is emitted.",
            ),
          )
        }
    }
  }
  {
    id,
    case_report,
    selection,
    bindings,
    findings,
    capture_start,
    capture_end,
  }
}

///|
fn transition(
  left : Step,
  right : Step,
  continuity : Bool,
  continuity_source : String,
) -> Transition {
  let id = left.id + " -> " + right.id
  let mut classification = None
  let mut evidence = Json::object({
    "capture_clock_continuity_source": Json::string(continuity_source),
  })
  let finding = match
    (left.selection, right.selection, left.capture_end, right.capture_start) {
    (Some(a), Some(b), Some(end), Some(start)) if @diagnostic.summarize(
        left.findings,
      ) ==
      @diagnostic.Pass &&
      @diagnostic.summarize(right.findings) == @diagnostic.Pass => {
      evidence = Json::object({
        "from_selection": selection_json(a),
        "to_selection": selection_json(b),
        "from_capture_end": stamp(end),
        "to_capture_start": stamp(start),
        "capture_clock_continuity_source": Json::string(continuity_source),
        "sender_changed": Json::boolean(a.sender != b.sender),
        "grandmaster_changed": Json::boolean(a.grandmaster != b.grandmaster),
        "offset_delta_computed": Json::boolean(false),
      })
      if !continuity ||
        a.capture_clock != b.capture_clock ||
        a.domain != b.domain ||
        a.receiver != b.receiver ||
        @observation.time_ns(end) >= @observation.time_ns(start) {
        note(
          id,
          "COMMISSION.TRANSITION.EVIDENCE",
          @diagnostic.InsufficientEvidence,
          [],
          "same receiver/domain, confirmed continuous capture clock and strictly ordered nonoverlapping quartet intervals",
          "continuity=" +
          continuity.to_string() +
          "; clocks=" +
          a.capture_clock +
          "," +
          b.capture_clock +
          "; domains=" +
          a.domain.to_string() +
          "," +
          b.domain.to_string() +
          "; receivers=" +
          a.receiver.label() +
          "," +
          b.receiver.label() +
          "; previous_end=" +
          @observation.time_ns(end).to_string() +
          "; next_start=" +
          @observation.time_ns(start).to_string(),
          "No cross-step transition conclusion or elapsed failover time is inferred.",
        )
      } else if (a.sender != b.sender || a.grandmaster != b.grandmaster) &&
        @observation.time_ns(a.stability_until) >=
        @observation.time_ns(b.decision_time) &&
        @observation.time_ns(b.stability_until) >=
        @observation.time_ns(a.decision_time) {
        note(
          id,
          "COMMISSION.TRANSITION.CONTRADICTORY_STABILITY",
          @diagnostic.Violation,
          [],
          "different selected upstream identities have nonoverlapping confirmed selection intervals",
          "from=[" +
          @observation.time_ns(a.decision_time).to_string() +
          "," +
          @observation.time_ns(a.stability_until).to_string() +
          "]; to=[" +
          @observation.time_ns(b.decision_time).to_string() +
          "," +
          @observation.time_ns(b.stability_until).to_string() +
          "]",
          "The same receiver/domain cannot continuously select two different upstream identities over an overlapping interval. Ordered quartet captures do not repair contradictory selection assertions.",
        )
      } else {
        let label = if a.grandmaster != b.grandmaster {
          if a.sender == b.sender {
            "upstream_grandmaster_changed"
          } else {
            "upstream_port_and_grandmaster_changed"
          }
        } else if a.sender != b.sender {
          "upstream_port_changed_same_grandmaster"
        } else {
          "unchanged"
        }
        classification = Some(label)
        note(
          id,
          "COMMISSION.TRANSITION.OBSERVED",
          @diagnostic.Pass,
          [],
          "adjacent valid selected-upstream bindings",
          label,
          "Only observed identities at the two accepted intervals are compared; no continuous port-state or switch instant is established.",
        )
      }
    }
    _ =>
      note(
        id,
        "COMMISSION.TRANSITION.EVIDENCE",
        @diagnostic.InsufficientEvidence,
        [],
        "both adjacent steps fully accepted",
        "one or both steps rejected or lack accepted quartet interval",
        "Rejected steps are never skipped to connect nonadjacent observations.",
      )
  }
  { from_step: left.id, to_step: right.id, finding, classification, evidence, }
}

///|
fn stability_conflict(
  left : Step,
  right : Step,
  continuity : Bool,
  continuity_source : String,
) -> StabilityConflict? {
  if !continuity ||
    @diagnostic.summarize(left.findings) != @diagnostic.Pass ||
    @diagnostic.summarize(right.findings) != @diagnostic.Pass {
    return None
  }
  let (a, b) = match (left.selection, right.selection) {
    (Some(a), Some(b)) => (a, b)
    _ => return None
  }
  if a.capture_clock != b.capture_clock ||
    a.domain != b.domain ||
    a.receiver != b.receiver ||
    (a.sender == b.sender && a.grandmaster == b.grandmaster) {
    return None
  }
  if @observation.time_ns(a.stability_until) <
    @observation.time_ns(b.decision_time) ||
    @observation.time_ns(b.stability_until) <
    @observation.time_ns(a.decision_time) {
    return None
  }
  let finding = note(
    left.id + " -> " + right.id,
    "COMMISSION.TRANSITION.CONTRADICTORY_STABILITY",
    @diagnostic.Violation,
    [],
    "all accepted selections on the same receiver/domain/continuous capture clock have consistent exclusive sender and grandmaster identities",
    "overlapping confirmed intervals from=[" +
    @observation.time_ns(a.decision_time).to_string() +
    "," +
    @observation.time_ns(a.stability_until).to_string() +
    "]; to=[" +
    @observation.time_ns(b.decision_time).to_string() +
    "," +
    @observation.time_ns(b.stability_until).to_string() +
    "]",
    "Campaign-wide premise consistency check; this pair is not an inferred transition and intervening steps cannot erase an earlier stability assertion.",
  )
  Some({
    from_step: left.id,
    to_step: right.id,
    finding,
    evidence: Json::object({
      "from_selection": selection_json(a),
      "to_selection": selection_json(b),
      "capture_clock_continuity_source": Json::string(continuity_source),
      "sender_changed": Json::boolean(a.sender != b.sender),
      "grandmaster_changed": Json::boolean(a.grandmaster != b.grandmaster),
      "transition_inferred": Json::boolean(false),
    }),
  })
}

///|
fn parse_campaign(input : String) -> Report raise {
  let value = @json.parse(
    input,
    reject_duplicate_keys=true,
    max_nesting_depth=40,
  )
  let m = fields(
    value,
    ["schema", "steps", "capture_clock_continuity"],
    "campaign",
  )
  if text(need(m, "schema")) != "ptp-commission/v1" {
    raise Invalid("expected ptp-commission/v1 schema")
  }
  let values = match need(m, "steps") {
    Array(a) if a.length() >= 1 && a.length() <= 16 => a
    Array(a) if a.length() > 16 =>
      return {
        steps: [],
        transitions: [],
        selection_conflicts: [],
        findings: [
          note(
            "campaign",
            "COMMISSION.INPUT.RESOURCE",
            @diagnostic.Unsupported,
            [],
            "at most 16 steps",
            a.length().to_string(),
            "Campaign step budget exceeded before any embedded case is evaluated.",
          ),
        ],
      }
    _ => raise Invalid("steps must contain 1..16 entries")
  }
  let (continuity, source) = match m.get("capture_clock_continuity") {
    None => (false, "")
    Some(v) => {
      let c = fields(v, ["source", "confirmed"], "capture_clock_continuity")
      let s = match c.get("source") {
        Some(v) => text(v)
        None => ""
      }
      (flag(c, "confirmed") && @observation.text_ok(s, 1024), s)
    }
  }
  let steps = []
  let ids = []
  let findings = []
  for v in values {
    let step = check_step(v)
    if ids.contains(step.id) {
      raise Invalid("duplicate step id: " + step.id)
    }
    ids.push(step.id)
    for f in step.findings {
      findings.push(f)
    }
    steps.push(step)
  }
  let transitions = []
  for i = 1; i < steps.length(); i = i + 1 {
    let t = transition(steps[i - 1], steps[i], continuity, source)
    findings.push(t.finding)
    transitions.push(t)
  }
  let selection_conflicts = []
  for i = 0; i < steps.length(); i = i + 1 {
    for j = i + 1; j < steps.length(); j = j + 1 {
      match stability_conflict(steps[i], steps[j], continuity, source) {
        Some(conflict) => {
          findings.push(conflict.finding)
          selection_conflicts.push(conflict)
        }
        None => ()
      }
    }
  }
  { steps, transitions, selection_conflicts, findings, }
}

///|
pub fn audit(input : String) -> Report {
  if input.length() > 1_048_576 {
    return {
      steps: [],
      transitions: [],
      selection_conflicts: [],
      findings: [
        note(
          "campaign",
          "COMMISSION.INPUT.RESOURCE",
          @diagnostic.Unsupported,
          [],
          "at most 1048576 UTF-16 units",
          input.length().to_string(),
          "Campaign input budget exceeded before parsing.",
        ),
      ],
    }
  }
  parse_campaign(input) catch {
    e =>
      {
        steps: [],
        transitions: [],
        selection_conflicts: [],
        findings: [
          note(
            "campaign",
            "COMMISSION.INPUT.SCHEMA",
            @diagnostic.Violation,
            [],
            "strict ptp-commission/v1 campaign",
            match e {
              Invalid(s) => s
              _ => "invalid JSON input"
            },
            "The malformed campaign has no partial acceptance report.",
          ),
        ],
      }
  }
}

///|
pub fn audit_json(input : String) -> String {
  audit(input).to_json().stringify(indent=2)
}
