///|
fn assert_status(
  actual : @diagnostic.Status,
  expected : @diagnostic.Status,
) -> Unit raise {
  assert_eq(actual.label(), expected.label())
}

///|
fn test_context() -> Context {
  {
    windows: [
      {
        id: "capture-a",
        epoch: 7,
        clock_domain: "capture-clock-a",
        start: { seconds: 100L, nanos: 0, },
        end: { seconds: 101L, nanos: 0, },
        complete: true,
      },
    ],
    policy: Some({
      source: "test device commissioning profile revision 1",
      sync_follow_up_ns: Some(1000L),
      delay_response_ns: Some(2000L),
    }),
  }
}

///|
fn test_sample(nanos : Int32) -> Sample {
  {
    frame: 1,
    epoch: Some(7),
    window: Some("capture-a"),
    time: Some({ seconds: 100L, nanos, }),
    clock_domain: Some("capture-clock-a"),
  }
}

///|
test "typed observation context validates explicit closed interval" {
  assert_status(
    @diagnostic.summarize(validate(test_context())),
    @diagnostic.Pass,
  )
}

///|
test "typed missing context is insufficient rather than protocol violation" {
  assert_status(
    @diagnostic.summarize(validate({ windows: [], policy: None, })),
    @diagnostic.InsufficientEvidence,
  )
}

///|
test "typed duplicate windows are ambiguous" {
  let original = test_context()
  let ctx : Context = {
    windows: [original.windows[0], original.windows[0]],
    policy: original.policy,
  }
  assert_true(get_window(ctx, "capture-a") is None)
  assert_status(
    @diagnostic.summarize(validate(ctx)),
    @diagnostic.InsufficientEvidence,
  )
}

///|
test "typed observation rejects negative epoch and invalid nanos" {
  let ctx = test_context()
  let window = ctx.windows[0]
  ctx.windows[0] = { ..window, epoch: -1, }
  assert_status(
    @diagnostic.summarize(validate(ctx)),
    @diagnostic.InsufficientEvidence,
  )
  ctx.windows[0] = {
    ..window,
    start: { seconds: 100L, nanos: 1_000_000_000, },
  }
  assert_status(
    @diagnostic.summarize(validate(ctx)),
    @diagnostic.InsufficientEvidence,
  )
}

///|
test "typed observation rejects reversed and unrepresentable time bounds" {
  let ctx = test_context()
  let window = ctx.windows[0]
  ctx.windows[0] = { ..window, start: window.end, end: window.start, }
  assert_status(
    @diagnostic.summarize(validate(ctx)),
    @diagnostic.InsufficientEvidence,
  )
  ctx.windows[0] = { ..window, end: { seconds: 281474976710656L, nanos: 0, }, }
  assert_status(
    @diagnostic.summarize(validate(ctx)),
    @diagnostic.InsufficientEvidence,
  )
}

///|
test "typed window resource ceiling prevents partial lookup" {
  let ctx = test_context()
  let too_many : Context = {
    windows: Array::make(65, ctx.windows[0]),
    policy: None,
  }
  assert_status(
    @diagnostic.summarize(validate(too_many)),
    @diagnostic.Unsupported,
  )
  assert_true(get_window(too_many, "capture-a") is None)
}

///|
test "typed policy requires source and positive provided budget" {
  let ctx = test_context()
  for
    policy in [
      { source: " ", sync_follow_up_ns: Some(1L), delay_response_ns: None, },
      {
        source: "device",
        sync_follow_up_ns: Some(0L),
        delay_response_ns: None,
      },
      {
        source: "device",
        sync_follow_up_ns: None,
        delay_response_ns: Some(-1L),
      },
    ] {
    assert_status(
      @diagnostic.summarize(validate({ ..ctx, policy: Some(policy), })),
      @diagnostic.InsufficientEvidence,
    )
  }
}

///|
test "group accepts boundary-equal freshness and arbitrary arrival order" {
  let findings = check_group(
    test_context(),
    [test_sample(1000), test_sample(0)],
    "TEST.GROUP",
    Some(1000L),
    true,
  )
  assert_status(@diagnostic.summarize(findings), @diagnostic.Pass)
  assert_eq(findings[0].frames.length(), 2)
}

///|
test "group expired one nanosecond beyond policy cannot pass" {
  assert_status(
    @diagnostic.summarize(
      check_group(
        test_context(),
        [test_sample(0), test_sample(1001)],
        "TEST.GROUP",
        Some(1000L),
        true,
      ),
    ),
    @diagnostic.InsufficientEvidence,
  )
}

///|
test "group missing epoch is never replaced by epoch zero" {
  let sample = test_sample(0)
  assert_status(
    @diagnostic.summarize(
      check_group(
        test_context(),
        [{ ..sample, epoch: None, }],
        "TEST.GROUP",
        Some(1000L),
        false,
      ),
    ),
    @diagnostic.InsufficientEvidence,
  )
}

///|
test "group missing each capture coordinate cannot pass" {
  let sample = test_sample(0)
  for
    incomplete in [
      { ..sample, window: None, },
      { ..sample, time: None, },
      { ..sample, clock_domain: None, },
    ] {
    assert_status(
      @diagnostic.summarize(
        check_group(
          test_context(),
          [incomplete],
          "TEST.GROUP",
          Some(1000L),
          false,
        ),
      ),
      @diagnostic.InsufficientEvidence,
    )
  }
}

///|
test "group cross epoch clock and window references are incomparable" {
  let sample = test_sample(0)
  for
    incompatible in [
      { ..sample, epoch: Some(8), },
      { ..sample, window: Some("unknown"), },
      { ..sample, clock_domain: Some("other-clock"), },
    ] {
    assert_status(
      @diagnostic.summarize(
        check_group(
          test_context(),
          [sample, incompatible],
          "TEST.GROUP",
          Some(1000L),
          false,
        ),
      ),
      @diagnostic.InsufficientEvidence,
    )
  }
}

///|
test "group capture timestamp outside closed window is insufficient" {
  let sample = test_sample(0)
  let outside_values : Array[@wire.PtpTimestamp] = [
    { seconds: 99L, nanos: 999999999, },
    { seconds: 101L, nanos: 1, },
  ]
  for outside in outside_values {
    assert_status(
      @diagnostic.summarize(
        check_group(
          test_context(),
          [{ ..sample, time: Some(outside), }],
          "TEST.GROUP",
          Some(1000L),
          false,
        ),
      ),
      @diagnostic.InsufficientEvidence,
    )
  }
}

///|
test "group completeness is a separately enforced premise" {
  let ctx = test_context()
  ctx.windows[0] = { ..ctx.windows[0], complete: false, }
  assert_status(
    @diagnostic.summarize(
      check_group(ctx, [test_sample(0)], "TEST.GROUP", Some(1000L), true),
    ),
    @diagnostic.InsufficientEvidence,
  )
  assert_status(
    @diagnostic.summarize(
      check_group(ctx, [test_sample(0)], "TEST.GROUP", Some(1000L), false),
    ),
    @diagnostic.Pass,
  )
}

///|
test "group refuses missing nonpositive budget and empty batch" {
  for budget in [None, Some(0L), Some(-1L)] {
    assert_status(
      @diagnostic.summarize(
        check_group(
          test_context(),
          [test_sample(0)],
          "TEST.GROUP",
          budget,
          true,
        ),
      ),
      @diagnostic.InsufficientEvidence,
    )
  }
  assert_status(
    @diagnostic.summarize(
      check_group(test_context(), [], "TEST.GROUP", Some(1000L), true),
    ),
    @diagnostic.InsufficientEvidence,
  )
}

///|
test "deadline requires coverage through the exact boundary" {
  let ctx = test_context()
  let sample = test_sample(999999999)
  let expired = deadline(ctx, sample, Some(1L), "TEST.DEADLINE")
  assert_status(expired.status, @diagnostic.InsufficientEvidence)
  assert_eq(
    expired.detail,
    "Observation window expired with no matching response under the supplied analysis policy. This is not proof of an IEEE device violation.",
  )
  let pending = deadline(ctx, sample, Some(2L), "TEST.DEADLINE")
  assert_status(pending.status, @diagnostic.InsufficientEvidence)
  assert_eq(
    pending.detail,
    "Observation remains pending: the complete capture ends before the supplied deadline.",
  )
}

///|
test "deadline capture loss cannot establish expiry" {
  let ctx = test_context()
  ctx.windows[0] = { ..ctx.windows[0], complete: false, }
  let finding = deadline(ctx, test_sample(0), Some(1L), "TEST.DEADLINE")
  assert_status(finding.status, @diagnostic.InsufficientEvidence)
  assert_eq(
    finding.detail,
    "Observation remains pending: window completeness was not confirmed; absence may be capture loss.",
  )
}

///|
test "deadline cannot infer expiry without epoch or policy" {
  let sample = test_sample(0)
  let missing_epoch = deadline(
    test_context(),
    { ..sample, epoch: None, },
    Some(1000L),
    "TEST.DEADLINE",
  )
  assert_status(missing_epoch.status, @diagnostic.InsufficientEvidence)
  let missing_budget = deadline(test_context(), sample, None, "TEST.DEADLINE")
  assert_status(missing_budget.status, @diagnostic.InsufficientEvidence)
}

///|
test "48-bit seconds remain exact beyond Int64 nanoseconds" {
  let maximum : @wire.PtpTimestamp = {
    seconds: 281474976710655L,
    nanos: 999999999,
  }
  assert_eq(time_ns(maximum).to_string(), "281474976710655999999999")
  let ctx = test_context()
  ctx.windows[0] = {
    ..ctx.windows[0],
    start: { seconds: maximum.seconds, nanos: 0, },
    end: maximum,
  }
  let sample = test_sample(0)
  let maximum_sample : Sample = { ..sample, time: Some(maximum), }
  let finding = deadline(
    ctx,
    maximum_sample,
    Some(9223372036854775807L),
    "TEST.DEADLINE",
  )
  assert_status(finding.status, @diagnostic.InsufficientEvidence)
  assert_eq(
    finding.detail,
    "Observation remains pending: the complete capture ends before the supplied deadline.",
  )
}

///|
test "group resource ceiling is enforced before serializing samples" {
  assert_status(
    @diagnostic.summarize(
      check_group(
        test_context(),
        Array::make(257, test_sample(0)),
        "TEST.GROUP",
        Some(1000L),
        true,
      ),
    ),
    @diagnostic.Unsupported,
  )
}
