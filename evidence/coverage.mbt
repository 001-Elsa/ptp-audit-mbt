///|
fn family_executed(
  findings : Array[@diagnostic.Finding],
  prefix : String,
) -> Bool {
  findings.any(fn(finding) { finding.rule.has_prefix(prefix) })
}

///|
/// This is execution coverage of this report, not a test-suite coverage claim.
/// Rules that did not run cannot inherit Pass from the overall summary.
pub fn coverage_json(findings : Array[@diagnostic.Finding]) -> Json {
  let rules : Array[String] = []
  let executed : Array[Json] = []
  for finding in findings {
    if !rules.contains(finding.rule) {
      rules.push(finding.rule)
      let statuses : Array[String] = []
      let observations : Array[Json] = []
      for result in findings {
        if result.rule == finding.rule {
          if !statuses.contains(result.status.label()) {
            statuses.push(result.status.label())
          }
          observations.push(
            Json::object({
              "status": Json::string(result.status.label()),
              "frames": ids_json(result.frames),
            }),
          )
        }
      }
      executed.push(
        Json::object({
          "rule": Json::string(finding.rule),
          "statuses": strings_json(statuses),
          "execution_count": number(observations.length()),
          "executions": Json::array(observations),
          "rule_reference": rule_reference_json(finding.rule),
        }),
      )
    }
  }
  let families = [
    "WIRE.", "OBSERVATION.", "EXCHANGE.", "CLAIM.", "MEASUREMENT.", "BMCA.",
  ]
  let not_executed = families.filter(fn(prefix) {
    !family_executed(findings, prefix)
  })
  Json::object({
    "meaning": Json::string(
      "Rules emitted by this input's execution; not a full normative or test coverage certificate.",
    ),
    "unique_rule_count": number(rules.length()),
    "finding_count": number(findings.length()),
    "executed_rules": Json::array(executed),
    "unreported_rule_families": strings_json(not_executed),
    "unreported_family_semantics": Json::string(
      "No finding was emitted from these families. Parsing may have rejected input earlier, or the input may omit that feature. Absence of a finding is not proof that the family passed.",
    ),
    "always_outside_scope": strings_json([
      "IEEE 1588 certification and complete normative conformance", "Hardware timestamp authenticity, transport interoperability and absolute clock accuracy",
      "Capture completeness independently verified from external evidence", "Announce qualification and the complete BMCA port-state algorithm",
      "Single-step, IEEE 1588-2019 minor version, 802.1AS, P2P, unicast/alternate-master modes and unknown TLVs",
      "Competition originality approval or acceptance of the submission",
    ]),
  })
}
