///|
/// Caller-supplied decision instant and maximum Announce age are observation
/// policy, never inferred from logMessageInterval or advertised as IEEE timeout.
pub(all) struct Snapshot {
  epoch : Int32?
  window : String?
  clock_domain : String?
  decision_time : @wire.PtpTimestamp?
  announce_validity_ns : Int64?
  validity_source : String?
  validity_confirmed : Bool
  capture_window_confirmed : Bool
  samples : Array[@observation.Sample]
}

///|
fn snapshot_problem(
  rule : String,
  frames : Array[Int32],
  expected : String,
  actual : String,
) -> @diagnostic.Finding {
  @diagnostic.finding(
    rule,
    @diagnostic.InsufficientEvidence,
    frames,
    None,
    expected,
    actual,
    "Dataset preference and observed device choice are not certified without a single current, complete observation snapshot.",
  )
}

///|
fn sample_for(
  samples : Array[@observation.Sample],
  frame : Int32,
) -> @observation.Sample? {
  let mut result = None
  for s in samples {
    if s.frame == frame {
      if result is Some(_) {
        return None
      }
      result = Some(s)
    }
  }
  result
}

///|
/// Validate every Announce against the same explicit decision epoch/window,
/// receiver clock domain and caller-confirmed effective validity policy before
/// executing the dataset comparison. No observed candidate is silently dropped.
pub fn audit(
  candidates : Array[Candidate],
  selected : String?,
  complete : Bool,
  eligible : Bool,
  context : @observation.Context,
  snapshot : Snapshot,
) -> Array[@diagnostic.Finding] {
  if candidates.is_empty() || candidates.length() > 64 || !complete || !eligible {
    return audit_preference(candidates, selected, complete, eligible)
  }
  let ids = candidates.map(fn(c) { c.frame })
  let context_findings = @observation.validate(context)
  if @diagnostic.summarize(context_findings) != @diagnostic.Pass {
    return context_findings
  }
  let (epoch, window, domain, decision, validity, source) = match
    (
      snapshot.epoch,
      snapshot.window,
      snapshot.clock_domain,
      snapshot.decision_time,
      snapshot.announce_validity_ns,
      snapshot.validity_source,
    ) {
    (Some(e), Some(w), Some(d), Some(t), Some(n), Some(s)) if e >= 0 &&
      @observation.text_ok(w, 128) &&
      @observation.text_ok(d, 128) &&
      n > 0L &&
      @observation.text_ok(s, 1024) &&
      @wire.valid_time(t) => (e, w, d, t, n, s)
    _ =>
      return [
        snapshot_problem(
          "BMCA.SNAPSHOT.EVIDENCE", ids, "explicit epoch/window/clock_domain/decision_time, positive announce_validity_ns and its source",
          "snapshot metadata missing or invalid",
        ),
      ]
  }
  if !snapshot.validity_confirmed || !snapshot.capture_window_confirmed {
    return [
      snapshot_problem(
        "BMCA.SNAPSHOT.EVIDENCE",
        ids,
        "announce_validity_confirmed=true and capture_window_confirmed=true",
        "validity=" +
        snapshot.validity_confirmed.to_string() +
        "; window=" +
        snapshot.capture_window_confirmed.to_string(),
      ),
    ]
  }
  let decision_sample : @observation.Sample = {
    frame: candidates[0].frame,
    epoch: Some(epoch),
    window: Some(window),
    time: Some(decision),
    clock_domain: Some(domain),
  }
  let findings = []
  for c in candidates {
    let observed = match sample_for(snapshot.samples, c.frame) {
      Some(s) => s
      None =>
        return [
          snapshot_problem(
            "BMCA.SNAPSHOT.EVIDENCE",
            [c.frame],
            "one capture metadata record for each candidate",
            "missing or duplicate metadata",
          ),
        ]
    }
    let checks = @observation.check_group(
      context,
      [observed, decision_sample],
      "BMCA.SNAPSHOT.WINDOW",
      Some(validity),
      true,
    )
    for item in checks {
      findings.push(item)
    }
    if @diagnostic.summarize(checks) != @diagnostic.Pass {
      return findings
    }
    let captured = match observed.time {
      Some(t) => @observation.time_ns(t)
      None => return findings
    }
    let age = @observation.time_ns(decision) - captured
    if age < @bigint.BigInt::from_int(0) ||
      age > @bigint.BigInt::from_int64(validity) {
      findings.push(
        snapshot_problem(
          "BMCA.SNAPSHOT.EXPIRED",
          [c.frame],
          "Announce at/before decision and within confirmed validity=" +
          validity.to_string() +
          " ns",
          "age=" + age.to_string() + " ns; source=" + source,
        ),
      )
      return findings
    }
    findings.push(
      @diagnostic.finding(
        "BMCA.SNAPSHOT.FRESH",
        @diagnostic.Pass,
        [c.frame],
        None,
        "0 <= decision_time - capture_time <= " + validity.to_string() + " ns",
        "age=" +
        age.to_string() +
        " ns; epoch=" +
        epoch.to_string() +
        "; window=" +
        window +
        "; domain=" +
        domain,
        "Caller-confirmed validity source=" +
        source +
        "; not foreign-master qualification or an inferred standard timeout.",
      ),
    )
  }
  for f in audit_preference(candidates, selected, complete, eligible) {
    findings.push(f)
  }
  findings
}
