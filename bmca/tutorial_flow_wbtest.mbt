// Independent branch expectations transcribed after visual review of the
// official-hosted Garner tutorial, pp. 61-62. The tutorial is non-normative.
// Provenance: research/normative-completion/bmca-tutorial-branch-review.json.

///|
fn tutorial_dataset(id : String, frame : Int32) -> Candidate {
  {
    id,
    frame,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 248,
      accuracy: 34,
      variance: 17185,
      priority2: 128,
      grandmaster: "0000000000000010",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
}

///|
fn tutorial_expect(
  a : Candidate,
  b : Candidate,
  side : Int32,
  topology : Bool,
  rule : String,
) -> Unit raise {
  let actual = compare(a, b)
  assert_eq(actual.side, side)
  assert_eq(actual.topology, topology)
  assert_eq(actual.rule, rule)
  assert_eq(
    actual.status.label(),
    if side == 0 {
      "Unsupported"
    } else {
      "Pass"
    },
  )
}

///|
fn tutorial_quality_expect(
  a : Candidate,
  b : Candidate,
  suffix : String,
) -> Unit raise {
  tutorial_expect(a, b, -1, false, "BMCA.DIFFERENT_GM." + suffix)
  tutorial_expect(b, a, 1, false, "BMCA.DIFFERENT_GM." + suffix)
}

///|
test "tutorial p61 priority1 precedes conflicting lower fields" {
  let a = tutorial_dataset("A", 1)
  let b = tutorial_dataset("B", 2)
  tutorial_quality_expect(
    {
      ..a,
      data: { ..a.data, priority1: 100, grandmaster: "0000000000000090", },
    },
    {
      ..b,
      data: {
        ..b.data,
        priority1: 101,
        clock_class: 6,
        accuracy: 32,
        variance: 1,
        priority2: 1,
      },
    },
    "priority1",
  )
}

///|
test "tutorial p61 clockClass precedes conflicting lower fields" {
  let a = tutorial_dataset("A", 1)
  let b = tutorial_dataset("B", 2)
  tutorial_quality_expect(
    {
      ..a,
      data: { ..a.data, clock_class: 6, grandmaster: "0000000000000090", },
    },
    {
      ..b,
      data: {
        ..b.data,
        clock_class: 7,
        accuracy: 32,
        variance: 1,
        priority2: 1,
      },
    },
    "clockClass",
  )
}

///|
test "tutorial p61 clockAccuracy precedes conflicting lower fields" {
  let a = tutorial_dataset("A", 1)
  let b = tutorial_dataset("B", 2)
  tutorial_quality_expect(
    { ..a, data: { ..a.data, accuracy: 32, grandmaster: "0000000000000090", }, },
    { ..b, data: { ..b.data, accuracy: 33, variance: 1, priority2: 1, }, },
    "clockAccuracy",
  )
}

///|
test "tutorial p61 variance precedes conflicting lower fields" {
  let a = tutorial_dataset("A", 1)
  let b = tutorial_dataset("B", 2)
  tutorial_quality_expect(
    {
      ..a,
      data: { ..a.data, variance: 100, grandmaster: "0000000000000090", },
    },
    { ..b, data: { ..b.data, variance: 101, priority2: 1, }, },
    "offsetScaledLogVariance",
  )
}

///|
test "tutorial p61 priority2 precedes opposing grandmaster identity" {
  let a = tutorial_dataset("A", 1)
  let b = tutorial_dataset("B", 2)
  tutorial_quality_expect(
    {
      ..a,
      data: { ..a.data, priority2: 100, grandmaster: "0000000000000090", },
    },
    { ..b, data: { ..b.data, priority2: 101, }, },
    "priority2",
  )
}

///|
test "tutorial p61 grandmaster identity breaks equal quality" {
  let a = tutorial_dataset("A", 1)
  let b = tutorial_dataset("B", 2)
  tutorial_quality_expect(
    a,
    { ..b, data: { ..b.data, grandmaster: "0000000000000011", }, },
    "identity",
  )
}

///|
test "tutorial p62 A plus one below B returns ordinary A better" {
  let a = tutorial_dataset("A", 1)
  let b = tutorial_dataset("B", 2)
  tutorial_expect(
    { ..a, data: { ..a.data, steps_removed: 1, }, },
    { ..b, data: { ..b.data, steps_removed: 3, }, },
    -1,
    false,
    "BMCA.SAME_GM.stepsRemoved",
  )
}

///|
test "tutorial p62 A above B plus one returns ordinary B better" {
  let a = tutorial_dataset("A", 1)
  let b = tutorial_dataset("B", 2)
  tutorial_expect(
    { ..a, data: { ..a.data, steps_removed: 3, }, },
    { ..b, data: { ..b.data, steps_removed: 1, }, },
    1,
    false,
    "BMCA.SAME_GM.stepsRemoved",
  )
}

///|
test "tutorial p62 longer A receiver below sender gives ordinary B better" {
  let a = tutorial_dataset("A", 1)
  let b = tutorial_dataset("B", 2)
  tutorial_expect(
    { ..a, sender: { clock: "0000000000000090", port: 1, }, },
    { ..b, data: { ..b.data, steps_removed: 1, }, },
    1,
    false,
    "BMCA.SAME_GM.oneHop",
  )
}

///|
test "tutorial p62 longer A receiver above sender gives topology B better" {
  let a = tutorial_dataset("A", 1)
  let b = tutorial_dataset("B", 2)
  tutorial_expect(
    a,
    { ..b, data: { ..b.data, steps_removed: 1, }, },
    1,
    true,
    "BMCA.SAME_GM.oneHop",
  )
}

///|
test "tutorial p62 longer A receiver equals sender gives error1" {
  let a = tutorial_dataset("A", 1)
  let b = tutorial_dataset("B", 2)
  tutorial_expect(
    { ..a, sender: a.receiver, },
    { ..b, data: { ..b.data, steps_removed: 1, }, },
    0,
    false,
    "BMCA.SAME_GM.error1",
  )
}

///|
test "tutorial p62 longer B receiver below sender gives ordinary A better" {
  let a = tutorial_dataset("A", 1)
  let b = tutorial_dataset("B", 2)
  tutorial_expect(
    { ..a, data: { ..a.data, steps_removed: 1, }, },
    { ..b, sender: { clock: "0000000000000090", port: 1, }, },
    -1,
    false,
    "BMCA.SAME_GM.oneHop",
  )
}

///|
test "tutorial p62 longer B receiver above sender gives topology A better" {
  let a = tutorial_dataset("A", 1)
  let b = tutorial_dataset("B", 2)
  tutorial_expect(
    { ..a, data: { ..a.data, steps_removed: 1, }, },
    b,
    -1,
    true,
    "BMCA.SAME_GM.oneHop",
  )
}

///|
test "tutorial p62 longer B receiver equals sender gives error1" {
  let a = tutorial_dataset("A", 1)
  let b = tutorial_dataset("B", 2)
  tutorial_expect(
    { ..a, data: { ..a.data, steps_removed: 1, }, },
    { ..b, sender: b.receiver, },
    0,
    false,
    "BMCA.SAME_GM.error1",
  )
}

///|
test "tutorial p62 equal steps smaller A sender gives topology A better" {
  let a = tutorial_dataset("A", 1)
  let b = tutorial_dataset("B", 2)
  tutorial_expect(
    a,
    { ..b, sender: { clock: "0000000000000030", port: 1, }, },
    -1,
    true,
    "BMCA.SAME_GM.sender",
  )
}

///|
test "tutorial p62 equal steps smaller B sender gives topology B better" {
  let a = tutorial_dataset("A", 1)
  let b = tutorial_dataset("B", 2)
  tutorial_expect(
    { ..a, sender: { clock: "0000000000000030", port: 1, }, },
    b,
    1,
    true,
    "BMCA.SAME_GM.sender",
  )
}

///|
test "tutorial p62 equal senders smaller A receiver port gives topology A better" {
  let a = tutorial_dataset("A", 1)
  let b = tutorial_dataset("B", 2)
  tutorial_expect(
    a,
    { ..b, receiver: { ..b.receiver, port: 2, }, },
    -1,
    true,
    "BMCA.SAME_GM.receiverPort",
  )
}

///|
test "tutorial p62 equal senders smaller B receiver port gives topology B better" {
  let a = tutorial_dataset("A", 1)
  let b = tutorial_dataset("B", 2)
  tutorial_expect(
    { ..a, receiver: { ..a.receiver, port: 2, }, },
    b,
    1,
    true,
    "BMCA.SAME_GM.receiverPort",
  )
}

///|
test "tutorial p62 equal sender and receiver port gives error2" {
  tutorial_expect(
    tutorial_dataset("A", 1),
    tutorial_dataset("B", 2),
    0,
    false,
    "BMCA.SAME_GM.error2",
  )
}
