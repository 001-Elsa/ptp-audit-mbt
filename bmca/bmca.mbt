///|
pub(all) struct Candidate {
  id : String
  frame : Int32
  domain : Int32
  data : @wire.AnnounceData
  sender : @wire.PortIdentity
  receiver : @wire.PortIdentity
}

///|
pub(all) struct Comparison {
  status : @diagnostic.Status
  // -1: left preferred; +1: right preferred; 0: not decidable in scope.
  side : Int32
  topology : Bool
  rule : String
  left : String
  right : String
}

///|
fn result(
  side : Int32,
  topology : Bool,
  rule : String,
  left : String,
  right : String,
) -> Comparison {
  { status: @diagnostic.Pass, side, topology, rule, left, right, }
}

///|
fn unresolved(rule : String, left : String, right : String) -> Comparison {
  {
    status: @diagnostic.Unsupported,
    side: 0,
    topology: false,
    rule,
    left,
    right,
  }
}

///|
fn cmp_port(a : @wire.PortIdentity, b : @wire.PortIdentity) -> Int32 {
  if a.clock < b.clock {
    -1
  } else if a.clock > b.clock {
    1
  } else if a.port < b.port {
    -1
  } else if a.port > b.port {
    1
  } else {
    0
  }
}

///|
fn valid(c : Candidate) -> Bool {
  let d = c.data
  c.id != "" &&
  c.domain >= 0 &&
  c.domain <= 255 &&
  @wire.valid_port(c.sender) &&
  @wire.valid_port(c.receiver) &&
  @wire.valid_port({ clock: d.grandmaster, port: 1, }) &&
  d.steps_removed >= 0 &&
  d.steps_removed < 255 &&
  d.priority1 >= 0 &&
  d.priority1 <= 255 &&
  d.clock_class >= 0 &&
  d.clock_class <= 255 &&
  d.accuracy >= 0 &&
  d.accuracy <= 255 &&
  d.variance >= 0 &&
  d.variance <= 65535 &&
  d.priority2 >= 0 &&
  d.priority2 <= 255
}

///|
/// Dataset comparison only. Does not implement qualification or port-state decision.
pub fn compare(a : Candidate, b : Candidate) -> Comparison {
  if !valid(a) || !valid(b) {
    return unresolved(
      "BMCA.SCOPE.DATASET", "valid qualified dataset, steps<255", "invalid or out-of-scope field",
    )
  }
  if a.domain != b.domain || a.receiver.clock != b.receiver.clock {
    return unresolved(
      "BMCA.SCOPE.CONTEXT",
      a.domain.to_string() + "/" + a.receiver.clock,
      b.domain.to_string() + "/" + b.receiver.clock,
    )
  }
  let x = a.data
  let y = b.data
  if x.grandmaster != y.grandmaster {
    let av = [x.priority1, x.clock_class, x.accuracy, x.variance, x.priority2]
    let bv = [y.priority1, y.clock_class, y.accuracy, y.variance, y.priority2]
    let names = [
      "priority1", "clockClass", "clockAccuracy", "offsetScaledLogVariance", "priority2",
    ]
    for i = 0; i < av.length(); i = i + 1 {
      if av[i] != bv[i] {
        return result(
          if av[i] < bv[i] {
            -1
          } else {
            1
          },
          false,
          "BMCA.DIFFERENT_GM." + names[i],
          av[i].to_string(),
          bv[i].to_string(),
        )
      }
    }
    return result(
      if x.grandmaster < y.grandmaster {
        -1
      } else {
        1
      },
      false,
      "BMCA.DIFFERENT_GM.identity",
      x.grandmaster,
      y.grandmaster,
    )
  }
  let sa = x.steps_removed
  let sb = y.steps_removed
  if sa + 1 < sb || sb + 1 < sa {
    return result(
      if sa < sb {
        -1
      } else {
        1
      },
      false,
      "BMCA.SAME_GM.stepsRemoved",
      sa.to_string(),
      sb.to_string(),
    )
  }
  if sa != sb {
    // A one-hop difference uses receiver vs sender of the longer path.
    let longer = if sa > sb { a } else { b }
    let order = cmp_port(longer.receiver, longer.sender)
    if order == 0 {
      return unresolved(
        "BMCA.SAME_GM.error1",
        longer.receiver.label(),
        longer.sender.label(),
      )
    }
    return result(
      if sa < sb {
        -1
      } else {
        1
      },
      order > 0,
      "BMCA.SAME_GM.oneHop",
      longer.receiver.label(),
      longer.sender.label(),
    )
  }
  let sender_order = cmp_port(a.sender, b.sender)
  if sender_order != 0 {
    return result(
      sender_order,
      true,
      "BMCA.SAME_GM.sender",
      a.sender.label(),
      b.sender.label(),
    )
  }
  if a.receiver.port != b.receiver.port {
    return result(
      if a.receiver.port < b.receiver.port {
        -1
      } else {
        1
      },
      true,
      "BMCA.SAME_GM.receiverPort",
      a.receiver.port.to_string(),
      b.receiver.port.to_string(),
    )
  }
  unresolved("BMCA.SAME_GM.error2", a.sender.label(), b.sender.label())
}

///|
fn audit_preference(
  candidates : Array[Candidate],
  selected : String?,
  complete : Bool,
  eligible : Bool,
) -> Array[@diagnostic.Finding] {
  let findings = []
  if candidates.is_empty() {
    return [
      @diagnostic.finding(
        "BMCA.EVIDENCE",
        @diagnostic.InsufficientEvidence,
        [],
        None,
        "nonempty qualified candidate set",
        "empty",
        "Local grandmaster election and port states are outside scope.",
      ),
    ]
  }
  if candidates.length() > 64 {
    return [
      @diagnostic.finding(
        "BMCA.RESOURCE",
        @diagnostic.Unsupported,
        [],
        None,
        "at most 64 candidates",
        candidates.length().to_string(),
        "Bounded comparison budget.",
      ),
    ]
  }
  for i = 0; i < candidates.length(); i = i + 1 {
    if !valid(candidates[i]) {
      return [
        @diagnostic.finding(
          "BMCA.SCOPE.DATASET",
          @diagnostic.Unsupported,
          [candidates[i].frame],
          None,
          "valid qualified dataset, stepsRemoved<255",
          "invalid/out of scope",
          "No preferred candidate inferred.",
        ),
      ]
    }
    for j = 0; j < i; j = j + 1 {
      if candidates[i].id == candidates[j].id ||
        candidates[i].frame == candidates[j].frame {
        return [
          @diagnostic.finding(
            "BMCA.CANDIDATE_UNIQUENESS",
            @diagnostic.Violation,
            [candidates[i].frame],
            None,
            "unique candidate ids and frame references",
            candidates[i].id,
            "Input candidate list duplicates an observation.",
          ),
        ]
      }
    }
  }
  if !complete || !eligible {
    return [
      @diagnostic.finding(
        "BMCA.EVIDENCE",
        @diagnostic.InsufficientEvidence,
        candidates.map(fn(c) { c.frame }),
        None,
        "complete and explicitly qualified snapshot",
        "assumptions not confirmed",
        "Announce observation alone cannot establish qualification or candidate-set completeness.",
      ),
    ]
  }
  let mut best = candidates[0]
  for i = 1; i < candidates.length(); i = i + 1 {
    let next = candidates[i]
    let r = compare(best, next)
    findings.push(
      @diagnostic.finding(
        r.rule,
        r.status,
        [best.frame, next.frame],
        None,
        r.left,
        r.right,
        if r.side == 0 {
          "Dataset comparison unresolved; no decision verdict."
        } else {
          "Preferred candidate: " +
          (if r.side < 0 { best.id } else { next.id }) +
          "; topology=" +
          r.topology.to_string()
        },
      ),
    )
    if r.side == 0 {
      return findings
    }
    if r.side > 0 {
      best = next
    }
  }
  // Verify a universal preferred dataset; do not assume a sorting comparator.
  for c in candidates {
    if c.id != best.id {
      let r = compare(best, c)
      if r.side >= 0 {
        findings.push(
          @diagnostic.finding(
            "BMCA.SCOPE.NO_UNIVERSAL_WINNER",
            @diagnostic.Unsupported,
            [best.frame, c.frame],
            None,
            "one preferred dataset against all candidates",
            "unresolved topology",
            "No total-order assumption is made.",
          ),
        )
        return findings
      }
    }
  }
  match selected {
    None =>
      findings.push(
        @diagnostic.finding(
          "BMCA.OBSERVED_DECISION",
          @diagnostic.InsufficientEvidence,
          [best.frame],
          None,
          best.id,
          "no observed selection",
          "Predicted preference is conditional on the supplied snapshot; actual device selection is unknown.",
        ),
      )
    Some(actual) =>
      findings.push(
        @diagnostic.finding(
          "BMCA.OBSERVED_DECISION",
          if actual == best.id {
            @diagnostic.Pass
          } else {
            @diagnostic.Violation
          },
          [best.frame],
          None,
          best.id,
          actual,
          "Dataset preference only, conditional on complete eligible snapshot. Not the full port-state algorithm.",
        ),
      )
  }
  findings
}
