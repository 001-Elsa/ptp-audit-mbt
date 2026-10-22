///|
/// Audit a bounded offline ptp-audit/v1 case. No networking or clock adjustment.
pub fn audit_json(text : String) -> String {
  @audit.audit_json(text)
}

///|
/// Audit a bounded PTP commissioning campaign; selection evidence is supplied
/// by the caller, and timing-limit verdicts remain separate from protocol status.
pub fn commission_json(text : String) -> String {
  @commissioning.audit_json(text)
}
