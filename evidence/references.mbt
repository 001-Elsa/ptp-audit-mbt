///|
fn upstream_reference(file : String, functions : Array[String]) -> Json {
  let (source_id, sha256) = match file {
    "msg.h" =>
      (
        "linuxptp-v4.4-msg-h", "4fcb3192f77ca15ab848857f21854bf3ac3d3d849ce47b97b071180cbb387c55",
      )
    "port.c" =>
      (
        "linuxptp-v4.4-port-c", "573073c076af3c0dcca33897a1474a2deac44191f40d7cf477260961aaaaeb96",
      )
    "bmc.c" =>
      (
        "linuxptp-v4.4-bmc-c", "5c85a38b2be84881354b123590a7d248ce87520150fed7adb178dcc44d9774d3",
      )
    _ => ("unregistered-upstream-source", "unverified")
  }
  Json::object({
    "source_id": Json::string(source_id),
    "sha256": Json::string(sha256),
    "hash_subject": Json::string(
      "Preserved upstream source file, not HTTP metadata or a product file.",
    ),
    "hash_register": Json::string(
      "research/implementation-reference/SHA256SUMS",
    ),
    "implementation": Json::string("LinuxPTP v4.4"),
    "source_url": Json::string(
      "https://github.com/richardcochran/linuxptp/blob/v4.4/" + file,
    ),
    "symbols": strings_json(functions),
    "role": Json::string(
      "Independently traceable implementation reference; not the IEEE normative text or a certification authority.",
    ),
  })
}

///|
fn local_reference(file : String, functions : Array[String]) -> Json {
  Json::object({
    "source_id": Json::string("project:" + file),
    "project_source": Json::string(file),
    "symbols": strings_json(functions),
    "sha256_register": Json::string(
      "research/normative-completion/rule-inventory.json#/sources",
    ),
    "hash_boundary": Json::string(
      "Resolve this project path in the generated inventory's sources table. Product hashes are registered after source freeze, rather than embedding a stale or circular self-hash in executable code.",
    ),
  })
}

///|
fn official_evidence(
  source_id : String,
  sha256 : String,
  title : String,
  url : String,
  locator : String,
  establishes : String,
  boundary : String,
  certainty : String,
) -> Json {
  Json::object({
    "source_id": Json::string(source_id),
    "sha256": Json::string(sha256),
    "hash_subject": Json::string(
      "Bytes of the reviewed official PDF; full document is not redistributed in the project.",
    ),
    "source": Json::string(title),
    "url": Json::string(url),
    "locator": Json::string(locator),
    "reviewed_fact": Json::string(establishes),
    "evidence_level": Json::string(certainty),
    "does_not_establish": Json::string(boundary),
    "source_register": Json::string("research/wire-reference/sources/README.md"),
    "source_access_register": Json::string(
      "research/normative-completion/source-access.json",
    ),
  })
}

///|
fn interpretation(
  locator : String,
  establishes : String,
  boundary : String,
) -> Json {
  official_evidence(
    "ieee1588-interpretations-2011", "fae8481cbaad0657d6e094a789cbf15afe57850991271d90fb9cdddc3fdb3bb5",
    "IEEE Standards Interpretations for IEEE Std 1588-2008, December 2011", "https://standards.ieee.org/wp-content/uploads/import/documents/interpretations/1588-2008_interp.pdf",
    locator, establishes, boundary, "reviewed_official_interpretation",
  )
}

///|
fn tutorial_evidence(
  locator : String,
  establishes : String,
  boundary : String,
) -> Json {
  official_evidence(
    "ieee802-garner-1588v2-tutorial-2008", "a023d1d55e20fe4b3ea5dbf11cdcfd650abfa071c3cab11e8247de6ff4eece68",
    "Geoffrey M. Garner, IEEE 1588 Version 2 tutorial, September 24 2008", "https://www.ieee802.org/1/files/public/docs2008/as-garner-1588v2-summary-0908.pdf",
    locator, establishes, boundary, "reviewed_non_normative_tutorial",
  )
}

///|
fn same_gm_tutorial_fact(rule : String) -> String? {
  match rule {
    "BMCA.SAME_GM.stepsRemoved" =>
      Some(
        "When stepsRemoved differ by more than one, the shorter path is ordinarily better.",
      )
    "BMCA.SAME_GM.oneHop" =>
      Some(
        "For a one-hop difference compare receiver identity with sender identity of the longer path: receiver<sender makes the shorter path ordinarily better; receiver>sender makes the shorter path better by topology.",
      )
    "BMCA.SAME_GM.error1" =>
      Some(
        "For a one-hop difference, equal receiver and sender identities on the longer path produce error1.",
      )
    "BMCA.SAME_GM.sender" =>
      Some(
        "With equal stepsRemoved, the smaller sender port identity is better by topology.",
      )
    "BMCA.SAME_GM.receiverPort" =>
      Some(
        "With equal stepsRemoved and sender identity, the smaller receiver port number is better by topology.",
      )
    "BMCA.SAME_GM.error2" =>
      Some(
        "With equal stepsRemoved, sender identity and receiver port number, dataset comparison returns error2.",
      )
    _ => None
  }
}

///|
/// Only records facts actually present in the retrieved public documents. A
/// table-of-contents locator remains a locator, not a reviewed normative clause.
fn official_basis(rule : String) -> Array[Json] {
  let facts = []
  if (
      rule.has_prefix("WIRE.") && rule != "WIRE.HEX" && rule != "WIRE.BODY_KIND"
    ) ||
    rule == "SCOPE.VERSION" ||
    rule == "SCOPE.PROFILE" ||
    rule == "SCOPE.MESSAGE" ||
    rule == "SCOPE.TLV" {
    facts.push(
      official_evidence(
        "iec61588-2009-official-preview", "e33a07902fcd4ea7812dc09cdb9be66f3cc72c71f38990fe531ea1a8c08ca439",
        "IEC 61588:2009 official preview", "https://webstore.iec.ch/en/iec_catalog/product/preview/?id=L3B1Yi9wZGYvcHJldmlldy9pbmZvX2llYzYxNTg4e2VkMi4wfWVuLnBkZg==",
        "Contents: Clause 13; Table 18; Tables 25-28", "The preview identifies the common header and Announce, Sync/Delay_Req, Follow_Up and Delay_Resp message-format tables.",
        "The contents page does not independently prove every body length, value range, control enumeration or rejection behavior.",
        "official_preview_locator_only",
      ),
    )
  }
  if rule == "WIRE.HEADER_LENGTH" ||
    rule == "WIRE.MESSAGE_LENGTH" ||
    rule == "WIRE.RESERVED" ||
    rule == "WIRE.CONTROL" ||
    rule == "WIRE.FIXED_BODY" {
    facts.push(
      official_evidence(
        "ieee802-cummings-header-contribution-2015", "862d9ea35675a982bf473ebfe0e3aa728286ffdd8cd32325acdcd9a2a14458db",
        "IEEE 802.1 public working-group contribution, March 2015", "https://www.ieee802.org/1/files/public/docs2015/as-cummings-1588-upkeep-work-item-89-0315-v1.pdf",
        "Page 4, reproduced Table 18 common-header offsets; page 2, reserved-field discussion",
        "Common-header offsets: correctionField 8/8 octets, sourcePortIdentity 20/10, sequenceId 30/2, controlField 32/1, logMessageInterval 33/1. Reserved fields are transmitted zero and ignored on receipt.",
        "A working-group contribution is not the normative standard. A nonzero reserved field cannot prove a receiver was required to reject the packet; control value enumerations remain unverified from full text.",
        "reviewed_non_normative_working_group_contribution",
      ),
    )
  }
  if rule == "WIRE.TWO_STEP_FLAG" ||
    rule == "SCOPE.TWO_STEP" ||
    rule == "EXCHANGE.SYNC_FOLLOW_UP" ||
    rule == "CLAIM.SYNC_FOLLOW_UP" {
    facts.push(
      interpretation(
        "Interpretation #11, page 7", "For a two-step Sync, the following Follow_Up copies flags with twoStepFlag set to FALSE; a two-step Sync indicates a following Follow_Up.",
        "This does not verify all Clause 11 matching, replay, timeout or capture-epoch behavior. Epoch/window are project evidence policy.",
      ),
    )
  }
  if rule.has_prefix("BMCA.DIFFERENT_GM.") {
    facts.push(
      interpretation(
        "Interpretation #31, page 28; Figure 27 / Clause 9.3.4", "Quality precedence is priority1, clockClass, clockAccuracy, variance, priority2, clockIdentity.",
        "This confirms comparison precedence only; it does not confirm candidate eligibility, all quality encodings, same-GM topology or port-state decisions.",
      ),
    )
  }
  if rule == "WIRE.SOURCE_PORT" || rule == "WIRE.REQUESTER_PORT" {
    facts.push(
      interpretation(
        "Interpretation #21, pages 14-15; subclause 7.5.2.3", "Device port numbers are 1..N where N is defaultDS.numberPorts.",
        "The auditor's nonzero UInt16 range 1..65535 cannot prove that an observed number is within the actual device's 1..N ports; defaultDS.numberPorts is not provided.",
      ),
    )
  }
  if rule == "SCOPE.CORRECTION_TOO_BIG" || rule == "MEASUREMENT.E2E" {
    facts.push(
      interpretation(
        "Interpretation #25, page 21; interpretation #27, pages 23-24", "correctionField is signed Integer64 and negative values are representable. The responses describe conflicting tooBig sentinels: 0x7fffffffffffffff versus all bits one.",
        "The auditor conservatively excludes both INT64_MAX and -1 from measurement. This local scope policy does not resolve the official conflict or establish one unambiguous normative sentinel.",
      ),
    )
  }
  if rule == "WIRE.TIMESTAMP" ||
    rule == "WIRE.NANOSECONDS" ||
    rule == "WIRE.RESPONSE" ||
    rule == "WIRE.ANNOUNCE" ||
    rule == "MEASUREMENT.E2E" ||
    rule == "SCOPE.CORRECTION_TOO_BIG" {
    facts.push(
      tutorial_evidence(
        "Page 45", "Timestamp contains UInteger48 seconds and UInteger32 nanoseconds. correctionField uses signed Integer64 in 2^-16 ns units.",
        "This tutorial does not establish nanoseconds<1000000000, every typed field range or a tooBig sentinel; it is not licensed normative text or a conformity certificate.",
      ),
    )
  }
  if rule.has_prefix("BMCA.DIFFERENT_GM.") {
    facts.push(
      tutorial_evidence(
        "Page 54", "The quality-field order shown is priority1, clockClass, clockAccuracy, offsetScaledLogVariance, priority2, clockIdentity.",
        "This is non-normative corroboration of ordering, not all code encodings, qualification or device state behavior.",
      ),
    )
  }
  match same_gm_tutorial_fact(rule) {
    Some(fact) =>
      facts.push(
        tutorial_evidence(
          "Pages 61-62, dataset comparison flow", fact, "The visually reviewed tutorial flow corroborates this branch only. Full normative Figures 27-28, candidate qualification and the complete port-state algorithm remain unverified from licensed normative text.",
        ),
      )
    None => ()
  }
  facts
}

///|
fn normative_gap(rule : String) -> String {
  if rule.has_prefix("METROLOGY.") {
    "Project PTP operand reconstruction and caller-bounded sensitivity assessment. No IEEE accuracy requirement, calibrated source authenticity or hardware acceptance is asserted."
  } else if rule == "WIRE.BODY_KIND" {
    "Typed MoonBit body/header variant consistency is a project API policy, not an IEEE wire-level shall."
  } else if rule == "WIRE.HEX" ||
    rule.has_prefix("OBSERVATION.") ||
    rule.has_prefix("INPUT.") ||
    rule.has_prefix("EXCHANGE.STATE.") ||
    rule.has_prefix("BMCA.SNAPSHOT.") ||
    rule == "SCOPE.CORRECTION_TOO_BIG" {
    "Project evidence, resource or bounded-scope policy; no IEEE requirement is asserted by this rule."
  } else if rule.has_prefix("BMCA.SAME_GM.") {
    "Garner tutorial pages 61-62 and LinuxPTP dscmp2 corroborate the stated branch, but full normative Figures 27-28 and device-state semantics remain unverified from licensed standard text."
  } else if rule == "WIRE.NANOSECONDS" || rule == "WIRE.TIMESTAMP" {
    "The accepted nanosecond bound and every timestamp range condition have not been independently verified against full normative pages; dissector/layout agreement is not a clause-level proof."
  } else {
    "The reviewed public facts are scoped evidence only. Complete licensed standard text and errata are not bundled or fully reviewed; unlisted conditions remain implementation/profile assumptions."
  }
}

///|
fn precise_basis(rule : String) -> String {
  match rule {
    "WIRE.BODY_KIND" => "project_typed_input_variant_policy"
    "WIRE.HEX" => "project_text_representation_policy"
    "WIRE.FIELD_RANGE" | "WIRE.ANNOUNCE" | "WIRE.RESPONSE" | "WIRE.TIMESTAMP" =>
      "typed_protocol_representation_boundary"
    _ =>
      if rule.has_prefix("WIRE.") {
        "bounded_protocol_encoding"
      } else if rule.has_prefix("BMCA.DIFFERENT_GM.") ||
        rule.has_prefix("BMCA.SAME_GM.") {
        "bounded_protocol_algorithm"
      } else if rule == "EXCHANGE.SYNC_FOLLOW_UP" ||
        rule == "CLAIM.SYNC_FOLLOW_UP" ||
        rule == "CLAIM.E2E_IDENTITY" ||
        rule == "MEASUREMENT.E2E" {
        "bounded_protocol_algorithm_with_evidence_preconditions"
      } else if rule.has_prefix("SCOPE.") ||
        rule.has_prefix("BMCA.SCOPE.") ||
        rule == "BMCA.RESOURCE" ||
        rule == "EXCHANGE.RESOURCE" {
        "project_scope_policy"
      } else {
        "project_input_or_evidence_policy"
      }
  }
}

///|
fn input_surface(rule : String) -> String {
  match rule {
    "WIRE.BODY_KIND"
    | "WIRE.FIELD_RANGE"
    | "WIRE.ANNOUNCE"
    | "WIRE.RESPONSE"
    | "WIRE.TIMESTAMP" => "typed_api_encode"
    "WIRE.HEX" => "text_hex_adapter"
    _ =>
      if rule.has_prefix("WIRE.") {
        "wire_payload_decode"
      } else if rule == "INPUT.SCHEMA" ||
        rule == "INPUT.RESOURCE" ||
        rule == "SCOPE.CASE" {
        "json_adapter"
      } else {
        "typed_audit_and_json_adapter"
      }
  }
}

///|
/// A traceable scope statement accompanies every rule. Local evidence policies
/// are deliberately not represented as requirements mandated by IEEE 1588.
pub fn rule_reference_json(rule : String) -> Json {
  let wire = rule.has_prefix("WIRE.")
  let association = rule == "EXCHANGE.SYNC_FOLLOW_UP" ||
    rule == "CLAIM.SYNC_FOLLOW_UP" ||
    rule == "CLAIM.E2E_IDENTITY"
  let measurement = rule == "MEASUREMENT.E2E"
  let dataset = rule.has_prefix("BMCA.DIFFERENT_GM.") ||
    rule.has_prefix("BMCA.SAME_GM.")
  let protocol = (wire && rule != "WIRE.HEX" && rule != "WIRE.BODY_KIND") ||
    association ||
    measurement ||
    dataset
  let topic = if rule == "SCOPE.CORRECTION_TOO_BIG" {
    "Project safety exclusion for conflicting public tooBig correction interpretations; no timing measurement is inferred from the excluded sentinel values"
  } else if rule.has_prefix("METROLOGY.") {
    "Accepted PTP quartet correction contribution ledger and conditional worst-case offset interval; the full forward-minus-reverse asymmetry bound and timestamp/correction errors are supplied by the caller"
  } else if rule == "WIRE.BODY_KIND" {
    "Typed MoonBit Packet body variant must agree with Header.kind before encoding; a local API representation policy"
  } else if rule == "WIRE.FIELD_RANGE" {
    "Typed header fields must fit accepted byte widths and canonical identity syntax; acceptance does not certify all device or profile constraints"
  } else if rule == "WIRE.ANNOUNCE" {
    "Typed Announce fields must fit accepted byte widths, identity syntax and bounded timestamp representation"
  } else if rule == "WIRE.RESPONSE" {
    "Typed Delay_Resp timestamp and requester must fit accepted representation bounds; actual device port-count validity is not established"
  } else if rule == "WIRE.TIMESTAMP" {
    "Typed timestamp must fit the accepted 48-bit seconds and sub-billion nanosecond representation; full normative bound is not certified"
  } else if rule == "WIRE.HEX" {
    "Project textual hexadecimal input syntax and resource budget; hexadecimal JSON text is not a PTP wire requirement"
  } else if wire {
    "PTP message header, fixed message bodies, field encodings and field value ranges"
  } else if association {
    "Two-step Sync/Follow_Up and E2E Delay_Req/Delay_Resp association fields; observation epoch/window is a project evidence policy"
  } else if measurement {
    "End-to-end four-timestamp offset and mean path delay calculation with correctionField in 2^-16 ns"
  } else if dataset {
    "Default BMCA dataset comparison; excludes qualification and port-state decision"
  } else {
    "Project input, bounded scope, observation validity, evidence completeness or reporting policy"
  }
  let upstream = if wire && rule != "WIRE.HEX" && rule != "WIRE.BODY_KIND" {
    [
      upstream_reference("msg.h", [
        "struct ptp_header", "struct sync_msg", "struct follow_up_msg", "struct delay_req_msg",
        "struct delay_resp_msg", "struct announce_msg",
      ]),
    ]
  } else if association || measurement {
    [
      upstream_reference("port.c", [
        "process_sync", "process_follow_up", "process_delay_resp", "port_synchronize",
      ]),
    ]
  } else if dataset {
    [upstream_reference("bmc.c", ["dscmp", "dscmp2"])]
  } else {
    []
  }
  let project_refs = if rule == "WIRE.HEX" {
    [local_reference("wire/wire.mbt", ["from_hex"])]
  } else if rule == "WIRE.BODY_KIND" ||
    rule == "WIRE.FIELD_RANGE" ||
    rule == "WIRE.TIMESTAMP" ||
    rule == "WIRE.RESPONSE" ||
    rule == "WIRE.ANNOUNCE" {
    [local_reference("wire/wire.mbt", ["encode", "valid_time", "valid_port"])]
  } else if wire {
    [
      local_reference("wire/wire.mbt", [
        "decode", "encode", "valid_time", "valid_port",
      ]),
    ]
  } else if rule.has_prefix("METROLOGY.") {
    [
      local_reference("metrology/metrology.mbt", ["explain", "assess"]),
      local_reference("audit/audit.mbt", ["parse_error_budget", "parse_case"]),
      local_reference("docs/commissioning.md", ["conditional_error_budget"]),
    ]
  } else if rule.has_prefix("OBSERVATION.") {
    [
      local_reference("observation/observation.mbt", [
        "validate", "get_window", "check_group", "deadline",
      ]),
    ]
  } else if rule == "EXCHANGE.SYNC_DEADLINE" ||
    rule == "EXCHANGE.DELAY_DEADLINE" {
    [
      local_reference("observation/observation.mbt", ["deadline"]),
      local_reference("exchange/exchange.mbt", ["audit"]),
    ]
  } else if rule.has_prefix("EXCHANGE.STATE.") {
    [
      local_reference("exchange/context.mbt", [
        "lifecycle_findings", "lifecycle_pair", "state_finding",
      ]),
      local_reference("observation/observation.mbt", [
        "check_group", "get_window",
      ]),
    ]
  } else if rule == "EXCHANGE.WINDOW" ||
    rule == "CLAIM.SYNC_WINDOW" ||
    rule == "CLAIM.DELAY_WINDOW" ||
    rule == "CLAIM.EXCHANGE_WINDOW" {
    [
      local_reference("observation/observation.mbt", ["check_group"]),
      local_reference("exchange/exchange.mbt", ["audit"]),
    ]
  } else if rule.has_prefix("BMCA.") {
    [
      local_reference("bmca/bmca.mbt", ["compare", "audit"]),
      local_reference("bmca/snapshot.mbt", ["audit", "sample_for"]),
      local_reference("audit/audit.mbt", ["parse_case"]),
    ]
  } else if rule.has_prefix("EXCHANGE.") ||
    rule.has_prefix("CLAIM.") ||
    rule.has_prefix("MEASUREMENT.") {
    [
      local_reference("exchange/exchange.mbt", [
        "audit", "sync_pair", "same_sync",
      ]),
    ]
  } else if rule.has_prefix("INPUT.") ||
    rule == "SCOPE.CASE" ||
    rule == "SCOPE.NO_SEMANTIC_CHECK" {
    [local_reference("audit/audit.mbt", ["parse_case", "audit", "audit_json"])]
  } else if rule.has_prefix("SCOPE.") {
    [
      local_reference("wire/wire.mbt", ["decode", "encode"]),
      local_reference("exchange/exchange.mbt", ["audit"]),
    ]
  } else {
    []
  }
  Json::object({
    "rule": Json::string(rule),
    "classification": Json::string(
      if protocol {
        "protocol_reference_with_bounded_scope"
      } else {
        "project_evidence_or_scope_policy"
      },
    ),
    "precise_basis_classification": Json::string(precise_basis(rule)),
    "input_surface": Json::string(input_surface(rule)),
    "topic": Json::string(topic),
    "standard": if protocol {
      Json::object({
        "title": Json::string("IEEE Std 1588-2008"),
        "doi": Json::string("https://doi.org/10.1109/IEEESTD.2008.4579760"),
        "normative_certification": Json::string("not_certified"),
        "clause_verification": Json::string(
          "No clause-level conformity certificate is inferred from implementation cross-checks; consult the project rule-basis record for the reviewed standard evidence and its access limits.",
        ),
      })
    } else {
      Json::null()
    },
    "upstream_sources": Json::array(upstream),
    "reviewed_official_evidence": Json::array(official_basis(rule)),
    "unverified_normative_boundary": Json::string(normative_gap(rule)),
    "project_sources": Json::array(project_refs),
    "rule_basis_document": Json::string("docs/rule-traceability.md"),
    "scope_document": Json::string("docs/rules.md"),
    "independent_wire_verification": Json::object({
      "document": Json::string("docs/wire-reference.md"),
      "evidence": Json::string("research/wire-reference/verification.json"),
      "boundary": Json::string(
        "Independent dissector agreement on the recorded fixtures supports those field layouts; it is not certification of every possible input or full IEEE conformity.",
      ),
    }),
    "verdict_boundary": Json::string(
      "This rule's status covers only its stated condition and supplied evidence. It does not certify full IEEE compliance, source authenticity, absolute timing accuracy, or competition originality.",
    ),
  })
}
