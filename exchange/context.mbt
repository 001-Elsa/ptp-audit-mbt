///|
pub fn sample(f : Frame) -> @observation.Sample {
  {
    frame: f.id,
    epoch: f.epoch,
    window: f.window,
    time: f.capture_time,
    clock_domain: f.capture_clock_domain,
  }
}

///|
fn sync_budget(context : @observation.Context) -> Int64? {
  match context.policy {
    Some(p) => p.sync_follow_up_ns
    None => None
  }
}

///|
fn delay_budget(context : @observation.Context) -> Int64? {
  match context.policy {
    Some(p) => p.delay_response_ns
    None => None
  }
}

///|
fn exchange_budget(context : @observation.Context) -> Int64? {
  match (sync_budget(context), delay_budget(context)) {
    (Some(a), Some(b)) => Some(if a > b { a } else { b })
    _ => None
  }
}

///|
priv struct PendingObservation {
  frame : Frame
  deadline : @bigint.BigInt
  ambiguous : Bool
}

///|
fn capture_partition(a : Frame, b : Frame) -> Bool {
  a.epoch == b.epoch &&
  a.window == b.window &&
  a.capture_clock_domain == b.capture_clock_domain
}

///|
fn lifecycle_kind(frame : Frame) -> Bool {
  frame.packet.header.kind == @wire.FollowUp ||
  frame.packet.header.kind == @wire.DelayReq ||
  frame.packet.header.kind == @wire.DelayResp ||
  (
    frame.packet.header.kind == @wire.Sync &&
    (frame.packet.header.flags & 512) != 0
  )
}

///|
fn lifecycle_budget(frame : Frame, context : @observation.Context) -> Int64? {
  match frame.packet.header.kind {
    @wire.Sync | @wire.FollowUp => sync_budget(context)
    @wire.DelayReq | @wire.DelayResp => delay_budget(context)
    @wire.Announce => None
  }
}

///|
fn lifecycle_same_key(a : Frame, b : Frame) -> Bool {
  if !capture_partition(a, b) ||
    a.packet.header.kind != b.packet.header.kind ||
    a.packet.header.domain != b.packet.header.domain ||
    a.packet.header.source != b.packet.header.source ||
    a.packet.header.sequence != b.packet.header.sequence {
    return false
  }
  match (a.packet.body, b.packet.body) {
    (@wire.Response(_, requester_a), @wire.Response(_, requester_b)) =>
      requester_a == requester_b
    _ => true
  }
}

///|
fn lifecycle_pair(
  frames : Array[Frame],
  claims : Array[ExchangeClaim],
  a : Frame,
  b : Frame,
) -> Bool {
  if !capture_partition(a, b) ||
    a.packet.header.domain != b.packet.header.domain {
    return false
  }
  if sync_pair(a, b) || sync_pair(b, a) {
    return true
  }
  let (request, response) = if a.packet.header.kind == @wire.DelayReq &&
    b.packet.header.kind == @wire.DelayResp {
    (a, b)
  } else if b.packet.header.kind == @wire.DelayReq &&
    a.packet.header.kind == @wire.DelayResp {
    (b, a)
  } else {
    return false
  }
  if request.packet.header.sequence != response.packet.header.sequence {
    return false
  }
  let requester = match response.packet.body {
    @wire.Response(_, value) => value
    _ => return false
  }
  if requester != request.packet.header.source {
    return false
  }
  // A Delay_Req does not encode its intended master. Only an explicit complete
  // association can supply this part of the lifecycle key. Matching these
  // states does not replace the formal four-frame verification in audit().
  let matching_claims = claims.filter(fn(claim) {
    if claim.delay_req != request.id || claim.delay_resp != response.id {
      return false
    }
    match (get_frame(frames, claim.sync), get_frame(frames, claim.follow_up)) {
      (Some(sync), Some(follow_up)) =>
        sync_pair(sync, follow_up) &&
        capture_partition(request, sync) &&
        capture_partition(request, follow_up) &&
        response.packet.header.source == sync.packet.header.source &&
        request.packet.header.domain == sync.packet.header.domain
      _ => false
    }
  })
  if matching_claims.length() != 1 {
    return false
  }
  // Conflicting claims concerning the same request cannot establish a unique
  // target master even when one of their responses happens to match.
  claims.filter(fn(claim) { claim.delay_req == request.id }).length() == 1
}

///|
fn state_finding(
  pending : PendingObservation,
  evicted : Bool,
  at_ns : @bigint.BigInt,
  reason : String,
) -> @diagnostic.Finding {
  @diagnostic.finding(
    if evicted {
      "EXCHANGE.STATE.EVICTED"
    } else {
      "EXCHANGE.STATE.PENDING"
    },
    @diagnostic.InsufficientEvidence,
    [pending.frame.id],
    None,
    "one unambiguous counterpart within the supplied analysis budget",
    "deadline_ns=" +
    pending.deadline.to_string() +
    "; observed_through_ns=" +
    at_ns.to_string() +
    "; ambiguous=" +
    pending.ambiguous.to_string() +
    "; sample=" +
    sample(pending.frame).to_json().stringify(),
    reason +
    " This is bounded capture-state management under analysis policy, not an IEEE device-violation conclusion.",
  )
}

///|
/// Replay independent capture partitions in timestamp order. A pending entry
/// is removed on an unambiguous timely match or physically evicted after its
/// deadline. Duplicated keys never consume a counterpart. Window exhaustion
/// establishes expiry only with producer-confirmed complete capture coverage.
fn lifecycle_findings(
  frames : Array[Frame],
  claims : Array[ExchangeClaim],
  context : @observation.Context,
) -> Array[@diagnostic.Finding] {
  let findings = []
  if frames.length() > 256 || claims.length() > 256 {
    return [
      @diagnostic.finding(
        "EXCHANGE.STATE.RESOURCE",
        @diagnostic.Unsupported,
        [],
        None,
        "at most 256 frames and claims",
        "state replay budget exceeded",
        "No partial replay is performed.",
      ),
    ]
  }
  let ordered = []
  for frame in frames {
    if !lifecycle_kind(frame) {
      continue
    }
    let prerequisite = @observation.check_group(
      context,
      [sample(frame)],
      "EXCHANGE.STATE.CONTEXT",
      lifecycle_budget(frame, context),
      false,
    )
    if @diagnostic.summarize(prerequisite) != @diagnostic.Pass {
      for item in prerequisite {
        findings.push(item)
      }
      continue
    }
    ordered.push(frame)
  }
  ordered.sort_by(fn(a, b) {
    let a_ns = @observation.time_ns(a.capture_time.unwrap())
    let b_ns = @observation.time_ns(b.capture_time.unwrap())
    if a_ns < b_ns {
      -1
    } else if a_ns > b_ns {
      1
    } else if a.id < b.id {
      -1
    } else if a.id > b.id {
      1
    } else {
      0
    }
  })
  let pending : Array[PendingObservation] = []
  for current in ordered {
    let now = @observation.time_ns(current.capture_time.unwrap())
    // Reverse removal ensures no expired state survives, including a state
    // whose same-key counterpart is the event now advancing the watermark.
    let mut i = pending.length() - 1
    while i >= 0 {
      let state = pending[i]
      if capture_partition(state.frame, current) && now > state.deadline {
        findings.push(
          state_finding(
            state, true, now, "Pending entry evicted before processing an event beyond its deadline.",
          ),
        )
        ignore(pending.remove(i))
      }
      i = i - 1
    }
    let ambiguous = frames
      .filter(fn(frame) { lifecycle_same_key(current, frame) })
      .length() !=
      1
    let mut match_index = -1
    if !ambiguous {
      for j = 0; j < pending.length(); j = j + 1 {
        if !pending[j].ambiguous &&
          lifecycle_pair(frames, claims, pending[j].frame, current) {
          if match_index != -1 {
            match_index = -2
            break
          }
          match_index = j
        }
      }
    }
    if match_index >= 0 {
      ignore(pending.remove(match_index))
    } else {
      let budget = lifecycle_budget(current, context).unwrap()
      pending.push({
        frame: current,
        deadline: now + @bigint.BigInt::from_int64(budget),
        ambiguous: ambiguous || match_index == -2,
      })
    }
  }
  let mut final_index = pending.length() - 1
  while final_index >= 0 {
    let state = pending[final_index]
    // Metadata was checked before insertion, so this lookup is total for each
    // state. Different epochs/windows/domains never advance one another.
    let window = @observation.get_window(context, state.frame.window.unwrap()).unwrap()
    let end_ns = @observation.time_ns(window.end)
    let expired = window.complete && end_ns >= state.deadline
    findings.push(
      state_finding(
        state,
        expired,
        end_ns,
        if expired {
          "Pending entry evicted at the complete observation window deadline."
        } else if !window.complete {
          "Pending entry retained: complete observation coverage was not confirmed."
        } else {
          "Pending entry retained: observation ends before its deadline."
        },
      ),
    )
    if expired {
      ignore(pending.remove(final_index))
    }
    final_index = final_index - 1
  }
  findings
}
