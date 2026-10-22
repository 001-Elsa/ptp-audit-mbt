///|
/// Capture time and clock_domain describe the observation clock, not a PTP
/// origin timestamp. An absent epoch is distinct from an explicitly supplied 0.
pub(all) struct Sample {
  frame : Int32
  epoch : Int32?
  window : String?
  time : @wire.PtpTimestamp?
  clock_domain : String?
}

///|
/// A closed capture interval. complete means the producer explicitly confirms
/// uninterrupted observation of the relevant traffic throughout this interval.
pub(all) struct Window {
  id : String
  epoch : Int32
  clock_domain : String
  start : @wire.PtpTimestamp
  end : @wire.PtpTimestamp
  complete : Bool
}

///|
/// Budgets are local analysis policy, not timeout values mandated by IEEE 1588.
/// The caller records a nonempty source so deadlines remain reproducible.
pub(all) struct Policy {
  source : String
  sync_follow_up_ns : Int64?
  delay_response_ns : Int64?
}

///|
pub(all) struct Context {
  windows : Array[Window]
  policy : Policy?
}

///|
/// Converts an already validated timestamp exactly. Call valid_time first for
/// untrusted typed API input; arbitrary 48-bit seconds do not fit Int64 nanos.
pub fn time_ns(time : @wire.PtpTimestamp) -> @bigint.BigInt {
  @bigint.BigInt::from_int64(time.seconds) *
  @bigint.BigInt::from_int(1_000_000_000) +
  @bigint.BigInt::from_int(time.nanos)
}

///|
/// Validity of the bounded 48-bit timestamp representation accepted by this
/// auditor. This does not establish clock provenance or PTP time-scale validity.
pub fn valid_time(time : @wire.PtpTimestamp) -> Bool {
  time.seconds >= 0L &&
  time.seconds <= 281474976710655L &&
  time.nanos >= 0 &&
  time.nanos < 1_000_000_000
}

///|
pub fn text_ok(text : String, maximum : Int32) -> Bool {
  if text.length() == 0 || text.length() > maximum {
    return false
  }
  let mut nonspace = false
  for i = 0; i < text.length(); i = i + 1 {
    let c = text.code_unit_at(i).to_int()
    if c < 32 || c == 127 {
      return false
    }
    if c != 32 {
      nonspace = true
    }
  }
  nonspace
}

///|
/// Returns no window for an absent or ambiguous id. validate must establish
/// window bounds and interval validity before using this result as evidence.
pub fn get_window(ctx : Context, id : String) -> Window? {
  if ctx.windows.length() > 64 {
    return None
  }
  let mut found = None
  for window in ctx.windows {
    if window.id == id {
      if found is Some(_) {
        return None
      }
      found = Some(window)
    }
  }
  found
}

///|
fn stamp_json(time : @wire.PtpTimestamp) -> Json {
  Json::object({
    "seconds": Json::string(time.seconds.to_string()),
    "nanoseconds": Json::number(time.nanos.to_double()),
  })
}

///|
/// Lossless evidence projection. seconds and budgets are decimal strings to
/// prevent consumers from rounding 48-bit-seconds calculations or Int64 policy.
pub fn Sample::to_json(self : Sample) -> Json {
  Json::object({
    "frame": Json::number(self.frame.to_double()),
    "epoch": match self.epoch {
      Some(value) => Json::number(value.to_double())
      None => Json::null()
    },
    "window": match self.window {
      Some(value) => Json::string(value)
      None => Json::null()
    },
    "capture_time": match self.time {
      Some(value) => stamp_json(value)
      None => Json::null()
    },
    "clock_domain": match self.clock_domain {
      Some(value) => Json::string(value)
      None => Json::null()
    },
  })
}

///|
/// Captures the producer's assertions verbatim; complete remains an assumption,
/// not a conclusion independently established by the auditor.
pub fn Window::to_json(self : Window) -> Json {
  Json::object({
    "id": Json::string(self.id),
    "epoch": Json::number(self.epoch.to_double()),
    "clock_domain": Json::string(self.clock_domain),
    "start": stamp_json(self.start),
    "end": stamp_json(self.end),
    "complete": Json::boolean(self.complete),
  })
}

///|
pub fn Policy::to_json(self : Policy) -> Json {
  Json::object({
    "source": Json::string(self.source),
    "sync_follow_up_ns": match self.sync_follow_up_ns {
      Some(value) => Json::string(value.to_string())
      None => Json::null()
    },
    "delay_response_ns": match self.delay_response_ns {
      Some(value) => Json::string(value.to_string())
      None => Json::null()
    },
  })
}

///|
pub fn Context::to_json(self : Context) -> Json {
  Json::object({
    "windows": Json::array(self.windows.map(fn(w) { w.to_json() })),
    "policy": match self.policy {
      Some(value) => value.to_json()
      None => Json::null()
    },
  })
}

///|
fn observation_finding(
  rule : String,
  status : @diagnostic.Status,
  frames : Array[Int32],
  expected : String,
  actual : String,
  detail : String,
) -> @diagnostic.Finding {
  @diagnostic.finding(rule, status, frames, None, expected, actual, detail)
}

///|
/// Validates typed API input independently of the JSON adapter. The context is
/// bounded to 64 unique windows. Invalid evidence cannot establish a device
/// violation. A missing policy is allowed until a deadline operation needs it.
pub fn validate(ctx : Context) -> Array[@diagnostic.Finding] {
  let findings = []
  if ctx.windows.length() > 64 {
    return [
      observation_finding(
        "OBSERVATION.RESOURCE",
        @diagnostic.Unsupported,
        [],
        "at most 64 observation windows",
        ctx.windows.length().to_string(),
        "The bounded auditor does not partially validate excess windows.",
      ),
    ]
  }
  if ctx.windows.is_empty() {
    findings.push(
      observation_finding(
        "OBSERVATION.WINDOW",
        @diagnostic.InsufficientEvidence,
        [],
        "at least one explicit observation window",
        "no windows",
        "An input batch alone establishes neither epoch nor capture coverage.",
      ),
    )
  }
  for i = 0; i < ctx.windows.length(); i = i + 1 {
    let window = ctx.windows[i]
    let errors : Array[String] = []
    if !text_ok(window.id, 128) {
      errors.push("invalid id (1..128 printable characters)")
    }
    if !text_ok(window.clock_domain, 128) {
      errors.push("invalid capture clock domain")
    }
    if window.epoch < 0 {
      errors.push("negative epoch")
    }
    if !valid_time(window.start) || !valid_time(window.end) {
      errors.push("timestamp outside 48-bit seconds / nanosecond bounds")
    } else if time_ns(window.start) > time_ns(window.end) {
      errors.push("start exceeds end")
    }
    for j = 0; j < i; j = j + 1 {
      if ctx.windows[j].id == window.id {
        errors.push("duplicate window id")
      }
    }
    findings.push(
      observation_finding(
        "OBSERVATION.WINDOW",
        if errors.is_empty() {
          @diagnostic.Pass
        } else {
          @diagnostic.InsufficientEvidence
        },
        [],
        "unique id, explicit nonnegative epoch, valid capture clock and ordered interval",
        window.to_json().stringify(),
        if errors.is_empty() {
          "Window representation is valid; producer coverage assertions remain assumptions."
        } else {
          errors.join("; ")
        },
      ),
    )
  }
  if ctx.policy is Some(policy) {
    let errors : Array[String] = []
    if !text_ok(policy.source, 1024) {
      errors.push("policy source must contain 1..1024 printable characters")
    }
    if policy.sync_follow_up_ns is Some(value) && value <= 0L {
      errors.push("sync_follow_up_ns must be positive")
    }
    if policy.delay_response_ns is Some(value) && value <= 0L {
      errors.push("delay_response_ns must be positive")
    }
    findings.push(
      observation_finding(
        "OBSERVATION.POLICY",
        if errors.is_empty() {
          @diagnostic.Pass
        } else {
          @diagnostic.InsufficientEvidence
        },
        [],
        "attributable source and positive provided budgets",
        policy.to_json().stringify(),
        if errors.is_empty() {
          "Budgets are analysis policy and do not assert a universal IEEE timeout."
        } else {
          errors.join("; ")
        },
      ),
    )
  }
  findings
}

///|
fn sample_errors(ctx : Context, sample : Sample) -> Array[String] {
  let errors = []
  if sample.frame < 0 {
    errors.push("negative frame id")
  }
  match sample.epoch {
    Some(value) => if value < 0 { errors.push("negative epoch") }
    None => errors.push("missing explicit epoch")
  }
  match sample.time {
    Some(time) =>
      if !valid_time(time) {
        errors.push("capture timestamp out of bounds")
      }
    None => errors.push("missing capture time")
  }
  match sample.clock_domain {
    Some(value) =>
      if !text_ok(value, 128) {
        errors.push("invalid capture clock domain")
      }
    None => errors.push("missing capture clock domain")
  }
  match sample.window {
    None => errors.push("missing observation window")
    Some(id) =>
      match get_window(ctx, id) {
        None => errors.push("window id absent or ambiguous")
        Some(window) => {
          if sample.epoch != Some(window.epoch) {
            errors.push("epoch differs from observation window")
          }
          if sample.clock_domain != Some(window.clock_domain) {
            errors.push("capture clock differs from observation window")
          }
          if sample.time is Some(time) && valid_time(time) {
            if time_ns(time) < time_ns(window.start) ||
              time_ns(time) > time_ns(window.end) {
              errors.push("capture time lies outside observation window")
            }
          }
        }
      }
  }
  errors
}

///|
/// Establishes comparable capture evidence for a bounded group. Every sample
/// must explicitly name the same epoch, window and capture clock. Positive
/// max_span_ns is mandatory; an unbounded group cannot prove freshness. No
/// protocol violation is inferred from absent, expired or incomparable input.
pub fn check_group(
  ctx : Context,
  samples : Array[Sample],
  rule : String,
  max_span_ns : Int64?,
  require_complete : Bool,
) -> Array[@diagnostic.Finding] {
  if samples.length() > 256 {
    return [
      observation_finding(
        rule,
        @diagnostic.Unsupported,
        [],
        "at most 256 samples per observation group",
        samples.length().to_string(),
        "No partial freshness proof is attempted beyond the bounded group size.",
      ),
    ]
  }
  let context_findings = validate(ctx)
  if @diagnostic.summarize(context_findings) != @diagnostic.Pass {
    return context_findings
  }
  let frames = samples.map(fn(sample) { sample.frame })
  let actual = Json::array(samples.map(fn(sample) { sample.to_json() })).stringify()
  let errors : Array[String] = []
  if samples.is_empty() {
    errors.push("a group requires at least one sample")
  }
  match max_span_ns {
    Some(value) =>
      if value <= 0L {
        errors.push("freshness budget must be positive")
      }
    None => errors.push("missing explicit freshness budget")
  }
  for sample in samples {
    for error in sample_errors(ctx, sample) {
      errors.push("frame " + sample.frame.to_string() + ": " + error)
    }
  }
  if !samples.is_empty() {
    let first = samples[0]
    for sample in samples {
      if sample.epoch != first.epoch ||
        sample.window != first.window ||
        sample.clock_domain != first.clock_domain {
        errors.push("samples do not share one epoch, window and capture clock")
      }
    }
    if require_complete && first.window is Some(id) {
      if get_window(ctx, id) is Some(window) && !window.complete {
        errors.push("producer did not confirm continuous complete observation")
      }
    }
  }
  if !errors.is_empty() {
    return [
      observation_finding(
        rule,
        @diagnostic.InsufficientEvidence,
        frames,
        "explicit comparable samples in one valid capture window and positive freshness budget",
        actual,
        errors.join("; "),
      ),
    ]
  }
  let mut minimum = time_ns(samples[0].time.unwrap())
  let mut maximum = minimum
  for sample in samples {
    let current = time_ns(sample.time.unwrap())
    if current < minimum {
      minimum = current
    }
    if current > maximum {
      maximum = current
    }
  }
  let span = maximum - minimum
  let limit = @bigint.BigInt::from_int64(max_span_ns.unwrap())
  let in_budget = span <= limit
  [
    observation_finding(
      rule,
      if in_budget {
        @diagnostic.Pass
      } else {
        @diagnostic.InsufficientEvidence
      },
      frames,
      "capture span <= " + limit.to_string() + " ns",
      "span=" + span.to_string() + " ns; samples=" + actual,
      if in_budget {
        "Explicit epoch, observation window, clock domain and freshness budget agree."
      } else {
        "Evidence expired under the supplied analysis policy; this is not an IEEE device violation."
      },
    ),
  ]
}

///|
/// Classifies a missing response using the producer's complete capture window.
/// Only a valid sample in a complete window reaching capture_time + budget can
/// establish observation expiry. Pending and expired both remain insufficient
/// evidence for a device violation. Arithmetic is exact even at 48-bit seconds.
pub fn deadline(
  ctx : Context,
  sample : Sample,
  budget_ns : Int64?,
  rule : String,
) -> @diagnostic.Finding {
  let errors : Array[String] = []
  let context_findings = validate(ctx)
  for finding in context_findings {
    if finding.status != @diagnostic.Pass {
      errors.push(finding.rule + ": " + finding.detail)
    }
  }
  for error in sample_errors(ctx, sample) {
    errors.push(error)
  }
  match budget_ns {
    Some(value) =>
      if value <= 0L {
        errors.push("deadline budget must be positive")
      }
    None => errors.push("missing explicit deadline budget")
  }
  if !errors.is_empty() {
    return observation_finding(
      rule,
      @diagnostic.InsufficientEvidence,
      [sample.frame],
      "valid capture sample, positive explicit budget and complete window through deadline",
      sample.to_json().stringify(),
      "Deadline not established: " + errors.join("; "),
    )
  }
  let window = get_window(ctx, sample.window.unwrap()).unwrap()
  let due = time_ns(sample.time.unwrap()) +
    @bigint.BigInt::from_int64(budget_ns.unwrap())
  let reached = time_ns(window.end) >= due
  observation_finding(
    rule,
    @diagnostic.InsufficientEvidence,
    [sample.frame],
    "response observed before supplied deadline or sufficient device evidence",
    "deadline_ns=" +
    due.to_string() +
    "; window_end_ns=" +
    time_ns(window.end).to_string() +
    "; complete=" +
    window.complete.to_string() +
    "; sample=" +
    sample.to_json().stringify(),
    if window.complete && reached {
      "Observation window expired with no matching response under the supplied analysis policy. This is not proof of an IEEE device violation."
    } else if !window.complete {
      "Observation remains pending: window completeness was not confirmed; absence may be capture loss."
    } else {
      "Observation remains pending: the complete capture ends before the supplied deadline."
    },
  )
}
