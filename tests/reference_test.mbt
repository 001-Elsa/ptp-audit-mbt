// Generated independent LinuxPTP v4.4 oracle vectors; see scripts/build_reference_vectors.py.

///|
test "LinuxPTP vector 0 different-priority1" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 0,
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
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 255,
      clock_class: 248,
      accuracy: 34,
      variance: 17185,
      priority2: 128,
      grandmaster: "0000000000000011",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.DIFFERENT_GM.priority1")
}

///|
test "LinuxPTP vector 1 reverse-priority1" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 255,
      clock_class: 248,
      accuracy: 34,
      variance: 17185,
      priority2: 128,
      grandmaster: "0000000000000011",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 0,
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
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.DIFFERENT_GM.priority1")
}

///|
test "LinuxPTP vector 2 different-clock_class" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 0,
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
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 255,
      accuracy: 34,
      variance: 17185,
      priority2: 128,
      grandmaster: "0000000000000011",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.DIFFERENT_GM.clockClass")
}

///|
test "LinuxPTP vector 3 reverse-clock_class" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 255,
      accuracy: 34,
      variance: 17185,
      priority2: 128,
      grandmaster: "0000000000000011",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 0,
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
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.DIFFERENT_GM.clockClass")
}

///|
test "LinuxPTP vector 4 different-accuracy" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 248,
      accuracy: 0,
      variance: 17185,
      priority2: 128,
      grandmaster: "0000000000000010",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 248,
      accuracy: 255,
      variance: 17185,
      priority2: 128,
      grandmaster: "0000000000000011",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.DIFFERENT_GM.clockAccuracy")
}

///|
test "LinuxPTP vector 5 reverse-accuracy" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 248,
      accuracy: 255,
      variance: 17185,
      priority2: 128,
      grandmaster: "0000000000000011",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 248,
      accuracy: 0,
      variance: 17185,
      priority2: 128,
      grandmaster: "0000000000000010",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.DIFFERENT_GM.clockAccuracy")
}

///|
test "LinuxPTP vector 6 different-variance" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 248,
      accuracy: 34,
      variance: 0,
      priority2: 128,
      grandmaster: "0000000000000010",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 248,
      accuracy: 34,
      variance: 65535,
      priority2: 128,
      grandmaster: "0000000000000011",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.DIFFERENT_GM.offsetScaledLogVariance")
}

///|
test "LinuxPTP vector 7 reverse-variance" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 248,
      accuracy: 34,
      variance: 65535,
      priority2: 128,
      grandmaster: "0000000000000011",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 248,
      accuracy: 34,
      variance: 0,
      priority2: 128,
      grandmaster: "0000000000000010",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.DIFFERENT_GM.offsetScaledLogVariance")
}

///|
test "LinuxPTP vector 8 different-priority2" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 248,
      accuracy: 34,
      variance: 17185,
      priority2: 0,
      grandmaster: "0000000000000010",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 248,
      accuracy: 34,
      variance: 17185,
      priority2: 255,
      grandmaster: "0000000000000011",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.DIFFERENT_GM.priority2")
}

///|
test "LinuxPTP vector 9 reverse-priority2" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 248,
      accuracy: 34,
      variance: 17185,
      priority2: 255,
      grandmaster: "0000000000000011",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 248,
      accuracy: 34,
      variance: 17185,
      priority2: 0,
      grandmaster: "0000000000000010",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.DIFFERENT_GM.priority2")
}

///|
test "LinuxPTP vector 10 gm-id" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 248,
      accuracy: 34,
      variance: 17185,
      priority2: 128,
      grandmaster: "0000000000000011",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.DIFFERENT_GM.identity")
}

///|
test "LinuxPTP vector 11 gm-id-reverse" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 248,
      accuracy: 34,
      variance: 17185,
      priority2: 128,
      grandmaster: "0000000000000011",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.DIFFERENT_GM.identity")
}

///|
test "LinuxPTP vector 12 far-hops" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 254,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.SAME_GM.stepsRemoved")
}

///|
test "LinuxPTP vector 13 far-hops" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 254,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.SAME_GM.stepsRemoved")
}

///|
test "LinuxPTP vector 14 one-hop-False-0000000000000070" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
    sender: { clock: "0000000000000070", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.SAME_GM.oneHop")
}

///|
test "LinuxPTP vector 15 one-hop-False-0000000000000080" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
    sender: { clock: "0000000000000080", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 0)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Unsupported")
  assert_eq(r.rule, "BMCA.SAME_GM.error1")
}

///|
test "LinuxPTP vector 16 one-hop-False-0000000000000090" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
    sender: { clock: "0000000000000090", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.SAME_GM.oneHop")
}

///|
test "LinuxPTP vector 17 one-hop-True-0000000000000070" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
    sender: { clock: "0000000000000070", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.SAME_GM.oneHop")
}

///|
test "LinuxPTP vector 18 one-hop-True-0000000000000080" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
    sender: { clock: "0000000000000080", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 0)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Unsupported")
  assert_eq(r.rule, "BMCA.SAME_GM.error1")
}

///|
test "LinuxPTP vector 19 one-hop-True-0000000000000090" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
    sender: { clock: "0000000000000090", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.SAME_GM.oneHop")
}

///|
test "LinuxPTP vector 20 sender_clock" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
    sender: { clock: "0000000000000021", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.SAME_GM.sender")
}

///|
test "LinuxPTP vector 21 sender_clock-reverse" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
    sender: { clock: "0000000000000021", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.SAME_GM.sender")
}

///|
test "LinuxPTP vector 22 sender_port" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
    sender: { clock: "0000000000000020", port: 2, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.SAME_GM.sender")
}

///|
test "LinuxPTP vector 23 sender_port-reverse" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
    sender: { clock: "0000000000000020", port: 2, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.SAME_GM.sender")
}

///|
test "LinuxPTP vector 24 receiver_port" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.SAME_GM.receiverPort")
}

///|
test "LinuxPTP vector 25 receiver_port-reverse" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
  assert_eq(r.rule, "BMCA.SAME_GM.receiverPort")
}

///|
test "LinuxPTP vector 26 error2" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 0)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Unsupported")
  assert_eq(r.rule, "BMCA.SAME_GM.error2")
}

///|
test "LinuxPTP vector 27 random-0" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
    sender: { clock: "000000000000008f", port: 1, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "000000000000006d", port: 4, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 28 random-1" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 13,
      clock_class: 212,
      accuracy: 220,
      variance: 2409,
      priority2: 50,
      grandmaster: "0000000000000015",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 224,
      clock_class: 111,
      accuracy: 99,
      variance: 61947,
      priority2: 187,
      grandmaster: "0000000000000021",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 29 random-2" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "000000000000008a", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "0000000000000091", port: 2, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 30 random-3" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 101,
      clock_class: 232,
      accuracy: 82,
      variance: 13242,
      priority2: 191,
      grandmaster: "000000000000003b",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 218,
      clock_class: 106,
      accuracy: 114,
      variance: 61524,
      priority2: 234,
      grandmaster: "000000000000006b",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 31 random-4" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "000000000000008e", port: 3, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "0000000000000090", port: 4, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 32 random-5" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 188,
      clock_class: 190,
      accuracy: 9,
      variance: 11454,
      priority2: 103,
      grandmaster: "00000000000000d5",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 8,
      clock_class: 45,
      accuracy: 76,
      variance: 21534,
      priority2: 176,
      grandmaster: "0000000000000018",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 33 random-6" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "0000000000000061", port: 4, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "0000000000000073", port: 1, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 34 random-7" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 164,
      clock_class: 204,
      accuracy: 169,
      variance: 60587,
      priority2: 208,
      grandmaster: "00000000000000f8",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 43,
      clock_class: 23,
      accuracy: 203,
      variance: 64646,
      priority2: 251,
      grandmaster: "0000000000000054",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 35 random-8" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "000000000000006e", port: 3, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "000000000000006f", port: 3, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 36 random-9" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 100,
      clock_class: 92,
      accuracy: 96,
      variance: 59119,
      priority2: 152,
      grandmaster: "0000000000000058",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 85,
      clock_class: 145,
      accuracy: 13,
      variance: 19685,
      priority2: 146,
      grandmaster: "000000000000005b",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 37 random-10" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "0000000000000067", port: 2, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "0000000000000084", port: 3, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 38 random-11" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 43,
      clock_class: 34,
      accuracy: 183,
      variance: 29388,
      priority2: 190,
      grandmaster: "0000000000000091",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 9,
      clock_class: 84,
      accuracy: 132,
      variance: 21828,
      priority2: 63,
      grandmaster: "0000000000000082",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 39 random-12" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "0000000000000082", port: 3, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "000000000000007c", port: 2, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 40 random-13" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 245,
      clock_class: 226,
      accuracy: 108,
      variance: 25646,
      priority2: 113,
      grandmaster: "0000000000000080",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 199,
      clock_class: 80,
      accuracy: 122,
      variance: 54132,
      priority2: 33,
      grandmaster: "000000000000004f",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 41 random-14" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "0000000000000073", port: 4, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "0000000000000069", port: 1, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 42 random-15" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 169,
      clock_class: 174,
      accuracy: 21,
      variance: 42619,
      priority2: 39,
      grandmaster: "0000000000000052",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 163,
      clock_class: 194,
      accuracy: 138,
      variance: 60675,
      priority2: 132,
      grandmaster: "000000000000001e",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 43 random-16" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "0000000000000076", port: 2, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "0000000000000070", port: 1, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 44 random-17" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 74,
      clock_class: 12,
      accuracy: 122,
      variance: 16861,
      priority2: 222,
      grandmaster: "00000000000000da",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 112,
      clock_class: 118,
      accuracy: 136,
      variance: 15372,
      priority2: 225,
      grandmaster: "00000000000000a9",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 45 random-18" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
    sender: { clock: "000000000000007b", port: 3, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "000000000000006b", port: 2, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 46 random-19" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 193,
      clock_class: 109,
      accuracy: 255,
      variance: 43607,
      priority2: 235,
      grandmaster: "0000000000000066",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 135,
      clock_class: 5,
      accuracy: 230,
      variance: 542,
      priority2: 163,
      grandmaster: "000000000000005f",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 47 random-20" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "000000000000009c", port: 2, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "0000000000000061", port: 1, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 48 random-21" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 221,
      clock_class: 130,
      accuracy: 223,
      variance: 19492,
      priority2: 96,
      grandmaster: "00000000000000ed",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 125,
      clock_class: 150,
      accuracy: 26,
      variance: 14042,
      priority2: 225,
      grandmaster: "0000000000000068",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 49 random-22" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "0000000000000083", port: 1, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "0000000000000083", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 50 random-23" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 31,
      clock_class: 14,
      accuracy: 183,
      variance: 49223,
      priority2: 224,
      grandmaster: "0000000000000041",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 95,
      clock_class: 232,
      accuracy: 58,
      variance: 63582,
      priority2: 197,
      grandmaster: "0000000000000020",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 51 random-24" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "0000000000000064", port: 2, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "0000000000000093", port: 1, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 52 random-25" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 110,
      clock_class: 111,
      accuracy: 227,
      variance: 43216,
      priority2: 165,
      grandmaster: "00000000000000be",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 99,
      clock_class: 170,
      accuracy: 225,
      variance: 59927,
      priority2: 172,
      grandmaster: "0000000000000006",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 53 random-26" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "000000000000006b", port: 4, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "000000000000007e", port: 2, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 54 random-27" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 179,
      clock_class: 133,
      accuracy: 126,
      variance: 31914,
      priority2: 58,
      grandmaster: "00000000000000d5",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 4,
      clock_class: 88,
      accuracy: 101,
      variance: 24488,
      priority2: 150,
      grandmaster: "00000000000000fe",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 55 random-28" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "0000000000000069", port: 3, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "0000000000000066", port: 1, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 56 random-29" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 172,
      clock_class: 227,
      accuracy: 150,
      variance: 11783,
      priority2: 242,
      grandmaster: "00000000000000d5",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 191,
      clock_class: 154,
      accuracy: 89,
      variance: 55338,
      priority2: 188,
      grandmaster: "0000000000000085",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 57 random-30" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "0000000000000084", port: 1, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
    sender: { clock: "0000000000000065", port: 2, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 58 random-31" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 150,
      clock_class: 211,
      accuracy: 162,
      variance: 37871,
      priority2: 40,
      grandmaster: "0000000000000029",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 108,
      clock_class: 245,
      accuracy: 250,
      variance: 30272,
      priority2: 66,
      grandmaster: "0000000000000002",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 59 random-32" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
    sender: { clock: "000000000000006f", port: 1, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
    sender: { clock: "0000000000000068", port: 1, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 60 random-33" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 48,
      clock_class: 224,
      accuracy: 115,
      variance: 11584,
      priority2: 203,
      grandmaster: "0000000000000075",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 165,
      clock_class: 46,
      accuracy: 164,
      variance: 65198,
      priority2: 103,
      grandmaster: "000000000000000d",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 61 random-34" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "0000000000000097", port: 3, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "000000000000008f", port: 4, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 62 random-35" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 66,
      clock_class: 29,
      accuracy: 249,
      variance: 28602,
      priority2: 165,
      grandmaster: "00000000000000af",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 71,
      clock_class: 113,
      accuracy: 130,
      variance: 40919,
      priority2: 251,
      grandmaster: "00000000000000ed",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 63 random-36" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "0000000000000082", port: 3, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "0000000000000092", port: 1, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 64 random-37" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 156,
      clock_class: 62,
      accuracy: 153,
      variance: 10900,
      priority2: 224,
      grandmaster: "0000000000000044",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 14,
      clock_class: 216,
      accuracy: 58,
      variance: 25519,
      priority2: 50,
      grandmaster: "00000000000000d2",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 65 random-38" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "0000000000000067", port: 4, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "0000000000000070", port: 2, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 66 random-39" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 65,
      clock_class: 218,
      accuracy: 106,
      variance: 62122,
      priority2: 41,
      grandmaster: "00000000000000ee",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 147,
      clock_class: 218,
      accuracy: 39,
      variance: 51669,
      priority2: 199,
      grandmaster: "00000000000000f0",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 67 random-40" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "0000000000000090", port: 4, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "000000000000009e", port: 1, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 68 random-41" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 194,
      clock_class: 17,
      accuracy: 114,
      variance: 2070,
      priority2: 88,
      grandmaster: "00000000000000bf",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 178,
      clock_class: 216,
      accuracy: 100,
      variance: 33093,
      priority2: 16,
      grandmaster: "000000000000009d",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 69 random-42" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "000000000000009f", port: 4, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "0000000000000089", port: 1, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 70 random-43" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 7,
      clock_class: 226,
      accuracy: 250,
      variance: 60619,
      priority2: 181,
      grandmaster: "00000000000000f9",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 81,
      clock_class: 77,
      accuracy: 99,
      variance: 38640,
      priority2: 94,
      grandmaster: "00000000000000c5",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 71 random-44" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "000000000000006d", port: 4, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "0000000000000065", port: 4, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 72 random-45" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 108,
      clock_class: 121,
      accuracy: 15,
      variance: 6781,
      priority2: 194,
      grandmaster: "000000000000002a",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 174,
      clock_class: 234,
      accuracy: 107,
      variance: 41080,
      priority2: 232,
      grandmaster: "000000000000005a",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 73 random-46" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
    sender: { clock: "000000000000008c", port: 2, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "0000000000000073", port: 2, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 74 random-47" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 209,
      clock_class: 129,
      accuracy: 129,
      variance: 48804,
      priority2: 254,
      grandmaster: "00000000000000fc",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 239,
      clock_class: 233,
      accuracy: 0,
      variance: 13619,
      priority2: 155,
      grandmaster: "000000000000002b",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 75 random-48" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "0000000000000067", port: 1, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "000000000000007c", port: 3, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 76 random-49" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 25,
      clock_class: 252,
      accuracy: 119,
      variance: 19933,
      priority2: 59,
      grandmaster: "00000000000000d5",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 220,
      clock_class: 69,
      accuracy: 36,
      variance: 51069,
      priority2: 248,
      grandmaster: "0000000000000022",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 77 random-50" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "000000000000009c", port: 2, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "000000000000008a", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 78 random-51" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 131,
      clock_class: 42,
      accuracy: 146,
      variance: 4152,
      priority2: 131,
      grandmaster: "0000000000000081",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 103,
      clock_class: 99,
      accuracy: 112,
      variance: 29560,
      priority2: 187,
      grandmaster: "0000000000000046",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 79 random-52" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "000000000000007a", port: 3, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "0000000000000089", port: 1, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 80 random-53" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 42,
      clock_class: 198,
      accuracy: 16,
      variance: 4553,
      priority2: 96,
      grandmaster: "000000000000008a",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 129,
      clock_class: 223,
      accuracy: 100,
      variance: 43201,
      priority2: 200,
      grandmaster: "0000000000000048",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 81 random-54" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "0000000000000075", port: 4, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "0000000000000095", port: 2, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 82 random-55" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 237,
      clock_class: 46,
      accuracy: 255,
      variance: 42548,
      priority2: 24,
      grandmaster: "00000000000000da",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 205,
      clock_class: 4,
      accuracy: 101,
      variance: 11761,
      priority2: 58,
      grandmaster: "00000000000000ba",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 83 random-56" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "000000000000006d", port: 1, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "0000000000000066", port: 2, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 84 random-57" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 167,
      clock_class: 4,
      accuracy: 141,
      variance: 44457,
      priority2: 11,
      grandmaster: "0000000000000024",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 11,
      clock_class: 98,
      accuracy: 20,
      variance: 49941,
      priority2: 208,
      grandmaster: "000000000000005f",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 85 random-58" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "000000000000007f", port: 1, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "000000000000009d", port: 3, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 86 random-59" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 62,
      clock_class: 67,
      accuracy: 67,
      variance: 55122,
      priority2: 242,
      grandmaster: "000000000000000f",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 31,
      clock_class: 39,
      accuracy: 157,
      variance: 41394,
      priority2: 164,
      grandmaster: "00000000000000e3",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 87 random-60" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "0000000000000060", port: 4, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "000000000000009a", port: 3, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 88 random-61" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 164,
      clock_class: 226,
      accuracy: 108,
      variance: 8589,
      priority2: 15,
      grandmaster: "0000000000000081",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 20,
      clock_class: 52,
      accuracy: 249,
      variance: 64183,
      priority2: 146,
      grandmaster: "000000000000005a",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 89 random-62" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "0000000000000062", port: 3, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "0000000000000069", port: 4, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 90 random-63" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 79,
      clock_class: 187,
      accuracy: 156,
      variance: 6440,
      priority2: 182,
      grandmaster: "0000000000000068",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 149,
      clock_class: 129,
      accuracy: 152,
      variance: 55409,
      priority2: 103,
      grandmaster: "0000000000000018",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 91 random-64" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "0000000000000083", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "0000000000000075", port: 3, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 92 random-65" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 104,
      accuracy: 248,
      variance: 40145,
      priority2: 119,
      grandmaster: "00000000000000d9",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 69,
      clock_class: 142,
      accuracy: 210,
      variance: 49210,
      priority2: 42,
      grandmaster: "0000000000000069",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 93 random-66" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "0000000000000095", port: 4, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "0000000000000086", port: 1, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 94 random-67" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 147,
      clock_class: 85,
      accuracy: 119,
      variance: 33759,
      priority2: 20,
      grandmaster: "0000000000000023",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 206,
      clock_class: 5,
      accuracy: 57,
      variance: 63464,
      priority2: 222,
      grandmaster: "00000000000000fc",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 95 random-68" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "0000000000000060", port: 1, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "0000000000000087", port: 2, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 96 random-69" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 112,
      clock_class: 29,
      accuracy: 179,
      variance: 64537,
      priority2: 124,
      grandmaster: "00000000000000fa",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 91,
      clock_class: 213,
      accuracy: 92,
      variance: 28539,
      priority2: 65,
      grandmaster: "00000000000000f7",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 97 random-70" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "0000000000000090", port: 1, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
    sender: { clock: "0000000000000078", port: 2, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 98 random-71" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 46,
      clock_class: 236,
      accuracy: 86,
      variance: 54440,
      priority2: 181,
      grandmaster: "000000000000003a",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 161,
      clock_class: 209,
      accuracy: 23,
      variance: 61254,
      priority2: 165,
      grandmaster: "000000000000001a",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 99 random-72" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "0000000000000069", port: 1, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "000000000000007f", port: 4, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 100 random-73" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 185,
      clock_class: 188,
      accuracy: 187,
      variance: 11544,
      priority2: 77,
      grandmaster: "000000000000002a",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 30,
      clock_class: 229,
      accuracy: 26,
      variance: 44060,
      priority2: 233,
      grandmaster: "000000000000007f",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 101 random-74" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "000000000000007f", port: 1, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "000000000000008f", port: 1, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 102 random-75" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 178,
      clock_class: 30,
      accuracy: 139,
      variance: 13492,
      priority2: 167,
      grandmaster: "00000000000000fe",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 14,
      clock_class: 107,
      accuracy: 55,
      variance: 30443,
      priority2: 76,
      grandmaster: "000000000000000f",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 103 random-76" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "0000000000000090", port: 3, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "0000000000000092", port: 2, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 104 random-77" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 219,
      clock_class: 20,
      accuracy: 48,
      variance: 20349,
      priority2: 49,
      grandmaster: "000000000000007e",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 75,
      clock_class: 169,
      accuracy: 71,
      variance: 4206,
      priority2: 252,
      grandmaster: "0000000000000085",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 105 random-78" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "0000000000000089", port: 1, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "0000000000000081", port: 4, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 106 random-79" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 111,
      clock_class: 201,
      accuracy: 184,
      variance: 32986,
      priority2: 131,
      grandmaster: "00000000000000a2",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 224,
      clock_class: 254,
      accuracy: 113,
      variance: 45425,
      priority2: 253,
      grandmaster: "000000000000006b",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 107 random-80" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
    sender: { clock: "0000000000000087", port: 1, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "0000000000000060", port: 2, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 108 random-81" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 33,
      clock_class: 88,
      accuracy: 176,
      variance: 935,
      priority2: 61,
      grandmaster: "000000000000008c",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 200,
      clock_class: 163,
      accuracy: 246,
      variance: 37929,
      priority2: 222,
      grandmaster: "000000000000002d",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 109 random-82" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "0000000000000076", port: 3, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "0000000000000085", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 110 random-83" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 179,
      clock_class: 14,
      accuracy: 197,
      variance: 36029,
      priority2: 145,
      grandmaster: "000000000000008a",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 109,
      clock_class: 165,
      accuracy: 48,
      variance: 41725,
      priority2: 121,
      grandmaster: "000000000000009a",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 111 random-84" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "000000000000007d", port: 1, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
    sender: { clock: "0000000000000076", port: 1, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 112 random-85" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 155,
      clock_class: 30,
      accuracy: 250,
      variance: 20390,
      priority2: 16,
      grandmaster: "00000000000000f2",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 238,
      clock_class: 61,
      accuracy: 56,
      variance: 30705,
      priority2: 107,
      grandmaster: "00000000000000b6",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 113 random-86" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "0000000000000072", port: 3, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "0000000000000094", port: 2, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 114 random-87" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 50,
      clock_class: 254,
      accuracy: 178,
      variance: 55587,
      priority2: 0,
      grandmaster: "00000000000000df",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 108,
      clock_class: 54,
      accuracy: 216,
      variance: 38146,
      priority2: 222,
      grandmaster: "00000000000000cc",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 115 random-88" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "000000000000006e", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "0000000000000083", port: 2, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 116 random-89" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 215,
      clock_class: 157,
      accuracy: 122,
      variance: 894,
      priority2: 84,
      grandmaster: "00000000000000fd",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 1,
      clock_class: 220,
      accuracy: 237,
      variance: 20470,
      priority2: 53,
      grandmaster: "00000000000000af",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 117 random-90" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "000000000000008c", port: 1, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "0000000000000090", port: 4, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 118 random-91" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 127,
      clock_class: 196,
      accuracy: 223,
      variance: 55154,
      priority2: 83,
      grandmaster: "00000000000000d0",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 227,
      clock_class: 180,
      accuracy: 219,
      variance: 471,
      priority2: 18,
      grandmaster: "0000000000000011",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 119 random-92" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "000000000000006f", port: 4, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "0000000000000092", port: 2, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 120 random-93" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 175,
      clock_class: 47,
      accuracy: 121,
      variance: 37737,
      priority2: 213,
      grandmaster: "0000000000000099",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 255,
      clock_class: 103,
      accuracy: 129,
      variance: 16486,
      priority2: 79,
      grandmaster: "00000000000000a9",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 121 random-94" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "0000000000000069", port: 1, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "0000000000000081", port: 4, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 122 random-95" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 136,
      clock_class: 161,
      accuracy: 236,
      variance: 40729,
      priority2: 188,
      grandmaster: "000000000000009f",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 211,
      clock_class: 225,
      accuracy: 96,
      variance: 58673,
      priority2: 103,
      grandmaster: "0000000000000049",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 123 random-96" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "000000000000007f", port: 4, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "0000000000000072", port: 3, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 124 random-97" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 14,
      clock_class: 61,
      accuracy: 196,
      variance: 58519,
      priority2: 55,
      grandmaster: "0000000000000094",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 131,
      clock_class: 82,
      accuracy: 99,
      variance: 2003,
      priority2: 7,
      grandmaster: "000000000000005b",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 125 random-98" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "0000000000000091", port: 3, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "000000000000009b", port: 1, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 126 random-99" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 167,
      clock_class: 134,
      accuracy: 205,
      variance: 1066,
      priority2: 72,
      grandmaster: "0000000000000036",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 249,
      clock_class: 238,
      accuracy: 200,
      variance: 18354,
      priority2: 99,
      grandmaster: "0000000000000010",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 127 random-100" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "0000000000000081", port: 3, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "000000000000006e", port: 3, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 128 random-101" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 247,
      clock_class: 253,
      accuracy: 165,
      variance: 28139,
      priority2: 232,
      grandmaster: "00000000000000d0",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 55,
      clock_class: 197,
      accuracy: 31,
      variance: 38183,
      priority2: 118,
      grandmaster: "0000000000000019",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 129 random-102" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "000000000000006d", port: 1, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "0000000000000073", port: 1, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 130 random-103" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 240,
      clock_class: 15,
      accuracy: 116,
      variance: 3439,
      priority2: 225,
      grandmaster: "0000000000000037",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 67,
      clock_class: 227,
      accuracy: 205,
      variance: 9810,
      priority2: 189,
      grandmaster: "0000000000000079",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 131 random-104" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "000000000000008f", port: 3, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "0000000000000088", port: 1, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 132 random-105" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 158,
      clock_class: 171,
      accuracy: 217,
      variance: 52318,
      priority2: 149,
      grandmaster: "000000000000005b",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 142,
      clock_class: 228,
      accuracy: 26,
      variance: 32743,
      priority2: 215,
      grandmaster: "0000000000000020",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 133 random-106" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "000000000000009e", port: 4, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "0000000000000083", port: 4, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 134 random-107" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 103,
      clock_class: 205,
      accuracy: 191,
      variance: 18387,
      priority2: 177,
      grandmaster: "00000000000000d3",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 84,
      clock_class: 9,
      accuracy: 108,
      variance: 18941,
      priority2: 198,
      grandmaster: "0000000000000040",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 135 random-108" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "0000000000000091", port: 3, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "0000000000000092", port: 3, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 136 random-109" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 5,
      clock_class: 191,
      accuracy: 126,
      variance: 22156,
      priority2: 64,
      grandmaster: "0000000000000018",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 47,
      clock_class: 55,
      accuracy: 204,
      variance: 13530,
      priority2: 11,
      grandmaster: "0000000000000075",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 137 random-110" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
    sender: { clock: "0000000000000077", port: 4, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "000000000000009b", port: 1, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 138 random-111" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 10,
      clock_class: 215,
      accuracy: 134,
      variance: 21312,
      priority2: 185,
      grandmaster: "0000000000000026",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 73,
      clock_class: 254,
      accuracy: 162,
      variance: 8117,
      priority2: 146,
      grandmaster: "00000000000000cc",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 139 random-112" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
    sender: { clock: "000000000000006c", port: 1, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
    sender: { clock: "0000000000000066", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 140 random-113" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 162,
      clock_class: 35,
      accuracy: 242,
      variance: 1154,
      priority2: 165,
      grandmaster: "00000000000000f2",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 213,
      clock_class: 34,
      accuracy: 81,
      variance: 63718,
      priority2: 239,
      grandmaster: "0000000000000002",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 141 random-114" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "0000000000000063", port: 2, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "0000000000000075", port: 3, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 142 random-115" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 83,
      clock_class: 172,
      accuracy: 149,
      variance: 42167,
      priority2: 3,
      grandmaster: "000000000000005b",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 136,
      clock_class: 151,
      accuracy: 195,
      variance: 3288,
      priority2: 147,
      grandmaster: "0000000000000014",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 143 random-116" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "000000000000007d", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
    sender: { clock: "000000000000009a", port: 3, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 144 random-117" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 89,
      clock_class: 84,
      accuracy: 135,
      variance: 37169,
      priority2: 95,
      grandmaster: "00000000000000c0",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 66,
      clock_class: 169,
      accuracy: 54,
      variance: 17890,
      priority2: 53,
      grandmaster: "00000000000000b5",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 145 random-118" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "0000000000000067", port: 1, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
    sender: { clock: "0000000000000078", port: 1, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 146 random-119" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 153,
      clock_class: 178,
      accuracy: 30,
      variance: 7241,
      priority2: 216,
      grandmaster: "00000000000000d2",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 188,
      clock_class: 25,
      accuracy: 88,
      variance: 29194,
      priority2: 197,
      grandmaster: "00000000000000c2",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 147 random-120" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "000000000000008a", port: 1, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "0000000000000074", port: 1, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 148 random-121" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 151,
      clock_class: 70,
      accuracy: 247,
      variance: 4120,
      priority2: 44,
      grandmaster: "00000000000000a5",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 116,
      clock_class: 24,
      accuracy: 228,
      variance: 31981,
      priority2: 165,
      grandmaster: "00000000000000c6",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 149 random-122" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "000000000000006d", port: 3, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "0000000000000099", port: 4, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 150 random-123" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 131,
      clock_class: 109,
      accuracy: 95,
      variance: 39397,
      priority2: 1,
      grandmaster: "000000000000009f",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 93,
      clock_class: 54,
      accuracy: 49,
      variance: 19092,
      priority2: 182,
      grandmaster: "0000000000000055",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 151 random-124" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "0000000000000065", port: 3, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "0000000000000086", port: 1, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 152 random-125" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 98,
      clock_class: 136,
      accuracy: 226,
      variance: 6300,
      priority2: 123,
      grandmaster: "00000000000000fc",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 213,
      clock_class: 72,
      accuracy: 21,
      variance: 15668,
      priority2: 50,
      grandmaster: "00000000000000a4",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 153 random-126" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "000000000000006e", port: 3, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "0000000000000068", port: 3, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 154 random-127" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 179,
      clock_class: 110,
      accuracy: 206,
      variance: 27857,
      priority2: 143,
      grandmaster: "0000000000000080",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 248,
      clock_class: 212,
      accuracy: 88,
      variance: 63925,
      priority2: 110,
      grandmaster: "000000000000003d",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 155 random-128" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "000000000000008d", port: 4, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "000000000000006f", port: 3, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 156 random-129" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 163,
      clock_class: 247,
      accuracy: 72,
      variance: 61954,
      priority2: 102,
      grandmaster: "00000000000000be",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 32,
      clock_class: 160,
      accuracy: 54,
      variance: 47586,
      priority2: 220,
      grandmaster: "00000000000000aa",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 157 random-130" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "0000000000000078", port: 1, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "0000000000000094", port: 2, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 158 random-131" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 83,
      clock_class: 239,
      accuracy: 58,
      variance: 39405,
      priority2: 122,
      grandmaster: "0000000000000091",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 108,
      clock_class: 19,
      accuracy: 207,
      variance: 6638,
      priority2: 87,
      grandmaster: "0000000000000096",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 159 random-132" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "000000000000006e", port: 2, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "0000000000000092", port: 2, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 160 random-133" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 43,
      clock_class: 249,
      accuracy: 125,
      variance: 905,
      priority2: 30,
      grandmaster: "0000000000000018",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 221,
      clock_class: 115,
      accuracy: 155,
      variance: 38382,
      priority2: 7,
      grandmaster: "0000000000000050",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 161 random-134" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "0000000000000067", port: 3, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
    sender: { clock: "000000000000008c", port: 2, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 162 random-135" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 249,
      clock_class: 248,
      accuracy: 31,
      variance: 20146,
      priority2: 111,
      grandmaster: "0000000000000014",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 234,
      clock_class: 79,
      accuracy: 79,
      variance: 62652,
      priority2: 255,
      grandmaster: "0000000000000003",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 163 random-136" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "0000000000000097", port: 3, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "0000000000000085", port: 3, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 164 random-137" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 118,
      clock_class: 0,
      accuracy: 24,
      variance: 13101,
      priority2: 0,
      grandmaster: "000000000000009b",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 104,
      clock_class: 215,
      accuracy: 55,
      variance: 5949,
      priority2: 202,
      grandmaster: "0000000000000037",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 165 random-138" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
    sender: { clock: "0000000000000062", port: 4, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "0000000000000079", port: 4, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 166 random-139" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 88,
      clock_class: 26,
      accuracy: 45,
      variance: 38875,
      priority2: 243,
      grandmaster: "00000000000000ef",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 42,
      clock_class: 26,
      accuracy: 88,
      variance: 43758,
      priority2: 150,
      grandmaster: "0000000000000058",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 167 random-140" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "0000000000000087", port: 3, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "0000000000000079", port: 2, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 168 random-141" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 73,
      clock_class: 219,
      accuracy: 227,
      variance: 29653,
      priority2: 79,
      grandmaster: "00000000000000b6",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 107,
      clock_class: 220,
      accuracy: 132,
      variance: 24693,
      priority2: 83,
      grandmaster: "0000000000000041",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 169 random-142" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "0000000000000065", port: 4, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "000000000000006b", port: 2, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 170 random-143" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 173,
      clock_class: 103,
      accuracy: 55,
      variance: 42580,
      priority2: 157,
      grandmaster: "0000000000000046",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 63,
      clock_class: 179,
      accuracy: 7,
      variance: 29263,
      priority2: 93,
      grandmaster: "000000000000003b",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 171 random-144" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "000000000000009e", port: 4, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "0000000000000081", port: 1, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 172 random-145" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 96,
      clock_class: 125,
      accuracy: 116,
      variance: 41771,
      priority2: 239,
      grandmaster: "00000000000000ca",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 41,
      clock_class: 26,
      accuracy: 15,
      variance: 3266,
      priority2: 151,
      grandmaster: "00000000000000f8",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 173 random-146" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
    sender: { clock: "0000000000000085", port: 2, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
    sender: { clock: "000000000000008d", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 174 random-147" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 21,
      clock_class: 195,
      accuracy: 71,
      variance: 29747,
      priority2: 130,
      grandmaster: "000000000000002c",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 95,
      clock_class: 113,
      accuracy: 80,
      variance: 20348,
      priority2: 95,
      grandmaster: "0000000000000098",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 175 random-148" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "000000000000007e", port: 3, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "0000000000000064", port: 4, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 176 random-149" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 53,
      clock_class: 148,
      accuracy: 176,
      variance: 19600,
      priority2: 102,
      grandmaster: "00000000000000bc",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 127,
      clock_class: 198,
      accuracy: 40,
      variance: 24455,
      priority2: 177,
      grandmaster: "0000000000000091",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 177 random-150" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
    sender: { clock: "0000000000000088", port: 1, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
    sender: { clock: "0000000000000074", port: 3, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 178 random-151" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 169,
      clock_class: 120,
      accuracy: 202,
      variance: 24609,
      priority2: 227,
      grandmaster: "0000000000000055",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 122,
      clock_class: 50,
      accuracy: 149,
      variance: 17165,
      priority2: 145,
      grandmaster: "00000000000000d1",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 179 random-152" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "0000000000000097", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "0000000000000072", port: 2, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 180 random-153" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 44,
      clock_class: 155,
      accuracy: 173,
      variance: 32235,
      priority2: 3,
      grandmaster: "000000000000003e",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 117,
      clock_class: 182,
      accuracy: 242,
      variance: 55585,
      priority2: 71,
      grandmaster: "00000000000000ab",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 181 random-154" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "0000000000000063", port: 4, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "000000000000006c", port: 2, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 182 random-155" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 128,
      clock_class: 19,
      accuracy: 245,
      variance: 3329,
      priority2: 127,
      grandmaster: "00000000000000ab",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 221,
      clock_class: 234,
      accuracy: 62,
      variance: 63799,
      priority2: 162,
      grandmaster: "000000000000009d",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 183 random-156" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "0000000000000086", port: 2, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "000000000000008d", port: 4, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 184 random-157" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 5,
      clock_class: 65,
      accuracy: 174,
      variance: 37010,
      priority2: 96,
      grandmaster: "0000000000000054",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 175,
      clock_class: 164,
      accuracy: 227,
      variance: 21853,
      priority2: 130,
      grandmaster: "00000000000000b9",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 185 random-158" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "0000000000000066", port: 3, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "0000000000000092", port: 1, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 186 random-159" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 150,
      clock_class: 163,
      accuracy: 17,
      variance: 17268,
      priority2: 243,
      grandmaster: "0000000000000093",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 127,
      clock_class: 31,
      accuracy: 98,
      variance: 26923,
      priority2: 39,
      grandmaster: "00000000000000c9",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 187 random-160" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
    sender: { clock: "0000000000000081", port: 3, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
    sender: { clock: "000000000000007d", port: 3, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 188 random-161" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 92,
      clock_class: 226,
      accuracy: 15,
      variance: 15014,
      priority2: 187,
      grandmaster: "0000000000000005",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 70,
      clock_class: 143,
      accuracy: 135,
      variance: 27302,
      priority2: 216,
      grandmaster: "00000000000000f4",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 189 random-162" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "0000000000000083", port: 3, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "000000000000008d", port: 2, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 190 random-163" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 0,
      clock_class: 61,
      accuracy: 7,
      variance: 14370,
      priority2: 103,
      grandmaster: "000000000000000e",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 104,
      clock_class: 196,
      accuracy: 254,
      variance: 18694,
      priority2: 225,
      grandmaster: "000000000000008d",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 191 random-164" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "0000000000000081", port: 4, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "000000000000006b", port: 3, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 192 random-165" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 205,
      clock_class: 116,
      accuracy: 6,
      variance: 44043,
      priority2: 41,
      grandmaster: "00000000000000b8",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 66,
      clock_class: 180,
      accuracy: 247,
      variance: 30621,
      priority2: 128,
      grandmaster: "0000000000000087",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 193 random-166" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 5,
      time_source: 160,
    },
    sender: { clock: "000000000000008c", port: 2, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "000000000000008b", port: 4, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 194 random-167" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 141,
      clock_class: 226,
      accuracy: 20,
      variance: 46959,
      priority2: 142,
      grandmaster: "000000000000001b",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 90,
      clock_class: 157,
      accuracy: 239,
      variance: 37242,
      priority2: 45,
      grandmaster: "0000000000000002",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 195 random-168" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
    sender: { clock: "000000000000006c", port: 3, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "000000000000008d", port: 4, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 196 random-169" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 226,
      clock_class: 63,
      accuracy: 191,
      variance: 21536,
      priority2: 214,
      grandmaster: "000000000000006e",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 141,
      clock_class: 213,
      accuracy: 145,
      variance: 12991,
      priority2: 179,
      grandmaster: "000000000000003e",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 197 random-170" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "000000000000007c", port: 4, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "0000000000000075", port: 2, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 198 random-171" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 221,
      clock_class: 174,
      accuracy: 175,
      variance: 1293,
      priority2: 110,
      grandmaster: "000000000000001c",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 56,
      clock_class: 153,
      accuracy: 105,
      variance: 44653,
      priority2: 13,
      grandmaster: "00000000000000e7",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 199 random-172" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "0000000000000095", port: 2, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "0000000000000096", port: 2, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 200 random-173" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 179,
      clock_class: 199,
      accuracy: 196,
      variance: 26211,
      priority2: 91,
      grandmaster: "00000000000000bd",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 67,
      clock_class: 216,
      accuracy: 189,
      variance: 51373,
      priority2: 118,
      grandmaster: "000000000000002b",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 201 random-174" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "000000000000007f", port: 4, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 6,
      time_source: 160,
    },
    sender: { clock: "000000000000007f", port: 1, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 202 random-175" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 254,
      clock_class: 56,
      accuracy: 158,
      variance: 6154,
      priority2: 71,
      grandmaster: "000000000000000e",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 101,
      clock_class: 63,
      accuracy: 196,
      variance: 52284,
      priority2: 10,
      grandmaster: "0000000000000028",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 203 random-176" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "000000000000009a", port: 1, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
    sender: { clock: "0000000000000081", port: 2, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 204 random-177" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 49,
      clock_class: 98,
      accuracy: 116,
      variance: 13534,
      priority2: 185,
      grandmaster: "00000000000000bb",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 213,
      clock_class: 236,
      accuracy: 72,
      variance: 30980,
      priority2: 129,
      grandmaster: "00000000000000d4",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 205 random-178" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "000000000000009d", port: 2, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "0000000000000092", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 206 random-179" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 157,
      clock_class: 18,
      accuracy: 172,
      variance: 51639,
      priority2: 32,
      grandmaster: "00000000000000e7",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 179,
      clock_class: 189,
      accuracy: 16,
      variance: 60476,
      priority2: 81,
      grandmaster: "0000000000000064",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 207 random-180" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "000000000000007b", port: 2, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "000000000000007e", port: 3, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 208 random-181" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 188,
      clock_class: 19,
      accuracy: 239,
      variance: 12774,
      priority2: 29,
      grandmaster: "0000000000000040",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 155,
      clock_class: 140,
      accuracy: 153,
      variance: 55137,
      priority2: 125,
      grandmaster: "0000000000000047",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 209 random-182" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "0000000000000073", port: 4, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
    sender: { clock: "000000000000007d", port: 2, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 210 random-183" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 34,
      clock_class: 199,
      accuracy: 242,
      variance: 23870,
      priority2: 255,
      grandmaster: "000000000000009e",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 213,
      clock_class: 141,
      accuracy: 21,
      variance: 53632,
      priority2: 133,
      grandmaster: "00000000000000cf",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 211 random-184" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "000000000000007a", port: 1, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 3,
      time_source: 160,
    },
    sender: { clock: "000000000000008d", port: 3, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 212 random-185" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 20,
      clock_class: 169,
      accuracy: 132,
      variance: 34993,
      priority2: 31,
      grandmaster: "0000000000000017",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 102,
      clock_class: 27,
      accuracy: 17,
      variance: 58366,
      priority2: 187,
      grandmaster: "00000000000000db",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 213 random-186" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "0000000000000093", port: 4, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 7,
      time_source: 160,
    },
    sender: { clock: "000000000000007b", port: 2, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, true)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 214 random-187" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 70,
      clock_class: 126,
      accuracy: 182,
      variance: 19960,
      priority2: 15,
      grandmaster: "00000000000000ba",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 34,
      clock_class: 104,
      accuracy: 176,
      variance: 62784,
      priority2: 95,
      grandmaster: "00000000000000ad",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, 1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 215 random-188" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 1,
      time_source: 160,
    },
    sender: { clock: "0000000000000063", port: 4, },
    receiver: { clock: "0000000000000080", port: 2, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
      steps_removed: 4,
      time_source: 160,
    },
    sender: { clock: "000000000000009d", port: 1, },
    receiver: { clock: "0000000000000080", port: 3, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 216 random-189" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 58,
      clock_class: 178,
      accuracy: 141,
      variance: 56299,
      priority2: 22,
      grandmaster: "00000000000000a3",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 135,
      clock_class: 186,
      accuracy: 29,
      variance: 46801,
      priority2: 232,
      grandmaster: "0000000000000031",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 217 random-190" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
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
      steps_removed: 0,
      time_source: 160,
    },
    sender: { clock: "0000000000000077", port: 3, },
    receiver: { clock: "0000000000000080", port: 4, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
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
    sender: { clock: "0000000000000081", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}

///|
test "LinuxPTP vector 218 random-191" {
  let a : @bmca.Candidate = {
    id: "A",
    frame: 1,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 19,
      clock_class: 87,
      accuracy: 70,
      variance: 64733,
      priority2: 63,
      grandmaster: "000000000000000f",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let b : @bmca.Candidate = {
    id: "B",
    frame: 2,
    domain: 0,
    data: {
      origin: { seconds: 0L, nanos: 0, },
      utc_offset: 37,
      priority1: 49,
      clock_class: 137,
      accuracy: 221,
      variance: 31237,
      priority2: 193,
      grandmaster: "00000000000000b4",
      steps_removed: 2,
      time_source: 160,
    },
    sender: { clock: "0000000000000020", port: 1, },
    receiver: { clock: "0000000000000080", port: 1, },
  }
  let r = @bmca.compare(a, b)
  assert_eq(r.side, -1)
  assert_eq(r.topology, false)
  assert_eq(r.status.label(), "Pass")
}
