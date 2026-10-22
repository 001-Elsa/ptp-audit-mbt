///|
pub(all) enum Status {
  Pass
  Violation
  InsufficientEvidence
  Unsupported
} derive(Eq)

///|
pub fn Status::label(self : Status) -> String {
  match self {
    Pass => "Pass"
    Violation => "Violation"
    InsufficientEvidence => "InsufficientEvidence"
    Unsupported => "Unsupported"
  }
}

///|
pub(all) struct Finding {
  rule : String
  status : Status
  frames : Array[Int32]
  offset : Int32?
  expected : String
  actual : String
  detail : String
}

///|
pub fn finding(
  rule : String,
  status : Status,
  frames : Array[Int32],
  offset : Int32?,
  expected : String,
  actual : String,
  detail : String,
) -> Finding {
  { rule, status, frames, offset, expected, actual, detail, }
}

///|
pub fn Finding::to_json(self : Finding) -> Json {
  Json::object({
    "rule": Json::string(self.rule),
    "status": Json::string(self.status.label()),
    "frames": Json::array(
      self.frames.map(fn(i) { Json::number(i.to_double()) }),
    ),
    "offset": match self.offset {
      Some(n) => Json::number(n.to_double())
      None => Json::null()
    },
    "expected": Json::string(self.expected),
    "actual": Json::string(self.actual),
    "detail": Json::string(self.detail),
  })
}

///|
pub fn summarize(findings : Array[Finding]) -> Status {
  if findings.is_empty() {
    return InsufficientEvidence
  }
  let mut result = Pass
  for f in findings {
    if f.status == Violation {
      return Violation
    }
    if f.status == Unsupported {
      result = Unsupported
    }
    if f.status == InsufficientEvidence && result == Pass {
      result = InsufficientEvidence
    }
  }
  result
}

///|
pub extend Status with Eq::{equal, not_equal}
