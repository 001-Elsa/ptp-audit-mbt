///|
pub(all) struct Frame {
  id : Int32
  epoch : Int32?
  window : String?
  capture_time : @wire.PtpTimestamp?
  capture_clock_domain : String?
  packet : @wire.Packet
  local_port : @wire.PortIdentity?
  event_time : @wire.PtpTimestamp?
  clock_domain : String?
  direction : String?
}

///|
pub(all) struct PairClaim {
  sync : Int32
  follow_up : Int32
}

///|
pub(all) struct ExchangeClaim {
  sync : Int32
  follow_up : Int32
  delay_req : Int32
  delay_resp : Int32
}

///|
pub(all) struct Measurement {
  frames : Array[Int32]
  offset_numerator : String
  delay_numerator : String
  denominator : Int32
  forward_scaled : String
  reverse_scaled : String
  sync_correction_scaled : String
  delay_correction_scaled : String
}

///|
pub(all) struct Report {
  findings : Array[@diagnostic.Finding]
  measurements : Array[Measurement]
}

///|
pub fn get_frame(frames : Array[Frame], id : Int32) -> Frame? {
  for f in frames {
    if f.id == id {
      return Some(f)
    }
  }
  None
}

///|
fn sync_pair(a : Frame, b : Frame) -> Bool {
  a.packet.header.kind == @wire.Sync &&
  b.packet.header.kind == @wire.FollowUp &&
  a.epoch is Some(_) &&
  a.epoch == b.epoch &&
  a.window == b.window &&
  a.packet.header.domain == b.packet.header.domain &&
  a.packet.header.source == b.packet.header.source &&
  a.packet.header.sequence == b.packet.header.sequence &&
  (a.packet.header.flags & 512) != 0
}

///|
fn same_sync(a : Frame, b : Frame) -> Bool {
  a.packet.header.kind == b.packet.header.kind &&
  a.epoch is Some(_) &&
  a.epoch == b.epoch &&
  a.window == b.window &&
  a.packet.header.domain == b.packet.header.domain &&
  a.packet.header.source == b.packet.header.source &&
  a.packet.header.sequence == b.packet.header.sequence
}

///|
fn nanos(t : @wire.PtpTimestamp) -> @bigint.BigInt {
  @bigint.BigInt::from_int64(t.seconds) *
  @bigint.BigInt::from_int(1_000_000_000) +
  @bigint.BigInt::from_int(t.nanos)
}

///|
pub fn audit(
  frames : Array[Frame],
  pairs : Array[PairClaim],
  exchanges : Array[ExchangeClaim],
  symmetric_path : Bool,
  timestamp_provenance : Bool,
  stable_rates : Bool,
  context : @observation.Context,
) -> Report {
  let findings = []
  let measurements = []
  if frames.length() > 256 || pairs.length() > 256 || exchanges.length() > 256 {
    return {
      findings: [
        @diagnostic.finding(
          "EXCHANGE.RESOURCE",
          @diagnostic.Unsupported,
          [],
          None,
          "at most 256 frames/claims",
          "budget exceeded",
          "No partial exchange verification performed.",
        ),
      ],
      measurements,
    }
  }
  let context_findings = @observation.validate(context)
  if @diagnostic.summarize(context_findings) != @diagnostic.Pass {
    return { findings: context_findings, measurements, }
  }
  for i = 0; i < frames.length(); i = i + 1 {
    for j = 0; j < i; j = j + 1 {
      if frames[i].id == frames[j].id {
        return {
          findings: [
            @diagnostic.finding(
              "INPUT.FRAME_ID",
              @diagnostic.Violation,
              [frames[i].id],
              None,
              "unique frame ids",
              "duplicate",
              "Observation identities must be unambiguous.",
            ),
          ],
          measurements,
        }
      }
    }
  }
  for f in frames {
    let bad_time = match f.event_time {
      Some(t) => !@wire.valid_time(t)
      None => false
    }
    let bad_port = match f.local_port {
      Some(p) => !@wire.valid_port(p)
      None => false
    }
    let bad_direction = match f.direction {
      Some(d) => d != "rx" && d != "tx"
      None => false
    }
    let bad_epoch = match f.epoch {
      Some(e) => e < 0
      None => false
    }
    if f.id < 0 || bad_epoch || bad_time || bad_port || bad_direction {
      return {
        findings: [
          @diagnostic.finding(
            "INPUT.FRAME_METADATA",
            @diagnostic.Violation,
            [f.id],
            None,
            "valid observation metadata",
            "invalid value",
            "Typed callers are validated before arithmetic.",
          ),
        ],
        measurements,
      }
    }
    match @wire.encode(f.packet) {
      Err(e) =>
        return {
          findings: [
            @diagnostic.finding(
              e.code,
              e.status,
              [f.id],
              Some(e.offset),
              e.expected,
              e.actual,
              "Invalid typed packet; no exchange arithmetic executed.",
            ),
          ],
          measurements,
        }
      Ok(_) => ()
    }
  }
  for f in frames {
    if f.packet.header.kind == @wire.Sync {
      if (f.packet.header.flags & 512) == 0 {
        findings.push(
          @diagnostic.finding(
            "SCOPE.TWO_STEP",
            @diagnostic.Unsupported,
            [f.id],
            Some(6),
            "twoStepFlag=1",
            "single-step Sync",
            "Only two-step synchronization association is supported.",
          ),
        )
        continue
      }
      let matches = frames.filter(fn(g) { sync_pair(f, g) })
      let repeated = frames.filter(fn(g) { same_sync(f, g) })
      if matches.length() == 1 && repeated.length() == 1 {
        let timing = @observation.check_group(
          context,
          [sample(f), sample(matches[0])],
          "EXCHANGE.WINDOW",
          sync_budget(context),
          true,
        )
        for item in timing {
          findings.push(item)
        }
        if @diagnostic.summarize(timing) != @diagnostic.Pass {
          continue
        }
        findings.push(
          @diagnostic.finding(
            "EXCHANGE.SYNC_FOLLOW_UP",
            @diagnostic.Pass,
            [f.id, matches[0].id],
            Some(20),
            "same epoch/domain/source/sequence",
            "unique matching pair",
            "Arrival order is irrelevant. This checks association only, not clock accuracy.",
          ),
        )
      } else {
        findings.push(
          @observation.deadline(
            context,
            sample(f),
            sync_budget(context),
            "EXCHANGE.SYNC_DEADLINE",
          ),
        )
        findings.push(
          @diagnostic.finding(
            "EXCHANGE.SYNC_FOLLOW_UP",
            @diagnostic.InsufficientEvidence,
            [f.id],
            Some(30),
            "one unambiguous pair in an observation epoch",
            matches.length().to_string() +
            " follow-ups, " +
            repeated.length().to_string() +
            " syncs",
            "Missing observation, duplication or sequence reuse cannot be resolved without more evidence. No <= sequence ordering is used.",
          ),
        )
      }
    }
    if f.packet.header.kind == @wire.FollowUp &&
      frames.filter(fn(g) { sync_pair(g, f) }).is_empty() {
      findings.push(
        @diagnostic.finding(
          "EXCHANGE.ORPHAN_FOLLOW_UP",
          @diagnostic.InsufficientEvidence,
          [f.id],
          Some(20),
          "observed matching two-step Sync",
          "none",
          "Capture completeness is not assumed.",
        ),
      )
    }
  }
  for c in pairs {
    match (get_frame(frames, c.sync), get_frame(frames, c.follow_up)) {
      (Some(a), Some(b)) => {
        let timing = @observation.check_group(
          context,
          [sample(a), sample(b)],
          "CLAIM.SYNC_WINDOW",
          sync_budget(context),
          true,
        )
        for item in timing {
          findings.push(item)
        }
        if @diagnostic.summarize(timing) != @diagnostic.Pass {
          continue
        }
        let ok = sync_pair(a, b)
        findings.push(
          @diagnostic.finding(
            "CLAIM.SYNC_FOLLOW_UP",
            if ok {
              @diagnostic.Pass
            } else {
              @diagnostic.Violation
            },
            [a.id, b.id],
            Some(20),
            "two-step Sync/Follow_Up with same epoch/domain/source/sequence",
            if ok {
              "matching"
            } else {
              "mismatching"
            },
            "Verdict applies to the explicitly asserted device association, not to mere coexistence of packets.",
          ),
        )
      }
      _ =>
        findings.push(
          @diagnostic.finding(
            "CLAIM.MISSING_FRAME",
            @diagnostic.InsufficientEvidence,
            [c.sync, c.follow_up],
            None,
            "both referenced observations",
            "missing frame",
            "No device association verdict inferred.",
          ),
        )
    }
  }
  for c in exchanges {
    let ids = [c.sync, c.follow_up, c.delay_req, c.delay_resp]
    if exchanges
      .filter(fn(other) {
        other.delay_req == c.delay_req || other.delay_resp == c.delay_resp
      })
      .length() !=
      1 {
      findings.push(
        @diagnostic.finding(
          "CLAIM.AMBIGUOUS",
          @diagnostic.InsufficientEvidence,
          ids,
          None,
          "one unambiguous claim per Delay_Req and Delay_Resp observation",
          "duplicate or conflicting request/response references",
          "Repeated claims cannot establish an independent measurement or a unique intended master.",
        ),
      )
      continue
    }
    match
      (
        get_frame(frames, c.sync),
        get_frame(frames, c.follow_up),
        get_frame(frames, c.delay_req),
        get_frame(frames, c.delay_resp),
      ) {
      (Some(s), Some(f), Some(q), Some(r)) => {
        let sync_timing = @observation.check_group(
          context,
          [sample(s), sample(f)],
          "CLAIM.SYNC_WINDOW",
          sync_budget(context),
          true,
        )
        let delay_timing = @observation.check_group(
          context,
          [sample(q), sample(r)],
          "CLAIM.DELAY_WINDOW",
          delay_budget(context),
          true,
        )
        let context_timing = @observation.check_group(
          context,
          [sample(s), sample(f), sample(q), sample(r)],
          "CLAIM.EXCHANGE_WINDOW",
          exchange_budget(context),
          true,
        )
        for item in sync_timing {
          findings.push(item)
        }
        for item in delay_timing {
          findings.push(item)
        }
        for item in context_timing {
          findings.push(item)
        }
        if @diagnostic.summarize(sync_timing) != @diagnostic.Pass ||
          @diagnostic.summarize(delay_timing) != @diagnostic.Pass ||
          @diagnostic.summarize(context_timing) != @diagnostic.Pass {
          continue
        }
        let hq = q.packet.header
        let hr = r.packet.header
        let requester = match r.packet.body {
          @wire.Response(_, p) => Some(p)
          _ => None
        }
        let request_ok = match requester {
          Some(p) => p == hq.source
          None => false
        }
        let ok = sync_pair(s, f) &&
          hq.kind == @wire.DelayReq &&
          hr.kind == @wire.DelayResp &&
          request_ok &&
          hq.domain == s.packet.header.domain &&
          hr.domain == hq.domain &&
          hq.sequence == hr.sequence &&
          hr.source == s.packet.header.source &&
          q.epoch == s.epoch &&
          r.epoch == s.epoch
        findings.push(
          @diagnostic.finding(
            "CLAIM.E2E_IDENTITY",
            if ok {
              @diagnostic.Pass
            } else {
              @diagnostic.Violation
            },
            ids,
            Some(20),
            "same epoch/domain, matching requester/sequence and selected master",
            if ok {
              "matching"
            } else {
              "mismatching"
            },
            "An explicit four-frame device association is being checked. Request correction is not counted twice.",
          ),
        )
        if !ok {
          continue
        }
        let unambiguous = frames.filter(fn(g) { same_sync(s, g) }).length() == 1 &&
          frames.filter(fn(g) { same_sync(f, g) }).length() == 1 &&
          frames.filter(fn(g) { same_sync(q, g) }).length() == 1 &&
          frames.filter(fn(g) { same_sync(r, g) }).length() == 1
        if !unambiguous {
          findings.push(
            @diagnostic.finding(
              "MEASUREMENT.AMBIGUOUS",
              @diagnostic.InsufficientEvidence,
              ids,
              None,
              "unique observation for each exchange key",
              "duplicate/reused sequence key",
              "An explicit claim cannot resolve ambiguous capture identity. No measurement emitted.",
            ),
          )
          continue
        }
        let times = match
          (f.packet.body, r.packet.body, s.event_time, q.event_time) {
          (@wire.TimestampBody(t1), @wire.Response(t4, _), Some(t2), Some(t3)) =>
            Some((t1, t2, t3, t4))
          _ => None
        }
        let metadata = match
          (
            s.local_port,
            q.local_port,
            s.clock_domain,
            q.clock_domain,
            s.direction,
            q.direction,
          ) {
          (Some(ps), Some(pq), Some(ds), Some(dq), Some("rx"), Some("tx")) =>
            ps == hq.source &&
            pq == hq.source &&
            @observation.text_ok(ds, 128) &&
            ds == dq
          _ => false
        }
        if !symmetric_path ||
          !timestamp_provenance ||
          !stable_rates ||
          !metadata ||
          times is None {
          findings.push(
            @diagnostic.finding(
              "MEASUREMENT.EVIDENCE",
              @diagnostic.InsufficientEvidence,
              ids,
              None,
              "t1..t4, same slave clock domain, rx/tx provenance, symmetric path, stable relative rates",
              "assumptions/metadata incomplete",
              "Packet timestamps are not interchangeable with NIC event timestamps. No absolute accuracy or path asymmetry inferred.",
            ),
          )
          continue
        }
        match times {
          Some((t1, t2, t3, t4)) => {
            let scale = @bigint.BigInt::from_int(65536)
            let sync_c = @bigint.BigInt::from_int64(s.packet.header.correction) +
              @bigint.BigInt::from_int64(f.packet.header.correction)
            let delay_c = @bigint.BigInt::from_int64(hr.correction)
            let forward = (nanos(t2) - nanos(t1)) * scale - sync_c
            let reverse = (nanos(t4) - nanos(t3)) * scale - delay_c
            if forward + reverse < @bigint.BigInt::from_int(0) {
              findings.push(
                @diagnostic.finding(
                  "MEASUREMENT.PATH_ASSUMPTIONS",
                  @diagnostic.InsufficientEvidence,
                  ids,
                  None,
                  "nonnegative mean path delay under assumptions",
                  "negative inferred delay",
                  "Contradictory timestamps/corrections or assumptions; not classified as a wire protocol violation.",
                ),
              )
              continue
            }
            measurements.push({
              frames: ids,
              offset_numerator: (forward - reverse).to_string(),
              delay_numerator: (forward + reverse).to_string(),
              denominator: 131072,
              forward_scaled: forward.to_string(),
              reverse_scaled: reverse.to_string(),
              sync_correction_scaled: sync_c.to_string(),
              delay_correction_scaled: delay_c.to_string(),
            })
            findings.push(
              @diagnostic.finding(
                "MEASUREMENT.E2E",
                @diagnostic.Pass,
                ids,
                None,
                "exact rational algebra under supplied assumptions",
                "offset and delay in 1/131072 ns units",
                "Uses arbitrary precision core integers internally. Not a clock-discipline or absolute-accuracy claim.",
              ),
            )
          }
          None => ()
        }
      }
      _ =>
        findings.push(
          @diagnostic.finding(
            "CLAIM.MISSING_FRAME",
            @diagnostic.InsufficientEvidence,
            ids,
            None,
            "four referenced observations",
            "missing frame",
            "No completed exchange inferred.",
          ),
        )
    }
  }
  for f in frames {
    if f.packet.header.kind == @wire.DelayReq ||
      f.packet.header.kind == @wire.DelayResp {
      if !exchanges.any(fn(c) { c.delay_req == f.id || c.delay_resp == f.id }) {
        if f.packet.header.kind == @wire.DelayReq {
          findings.push(
            @observation.deadline(
              context,
              sample(f),
              delay_budget(context),
              "EXCHANGE.DELAY_DEADLINE",
            ),
          )
        }
        findings.push(
          @diagnostic.finding(
            "EXCHANGE.DELAY_CONTEXT",
            @diagnostic.InsufficientEvidence,
            [f.id],
            None,
            "explicit four-frame association including selected master",
            "unassociated delay observation",
            "A Delay_Req payload alone does not identify its intended master.",
          ),
        )
      }
    }
  }
  for item in lifecycle_findings(frames, exchanges, context) {
    findings.push(item)
  }
  { findings, measurements, }
}
