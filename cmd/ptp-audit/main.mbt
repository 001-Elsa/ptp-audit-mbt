///|
extern "js" fn input() -> String =
  #| () => globalThis.__ptpAuditInput

///|
extern "js" fn json_mode() -> Bool =
  #| () => globalThis.__ptpAuditJson

///|
extern "js" fn command() -> String =
  #| () => globalThis.__ptpAuditCommand

///|
extern "js" fn set_exit(code : Int32) -> Unit =
  #| (code) => { process.exitCode = code; }

///|
fn main {
  if command() == "commission" {
    let report = @commissioning.audit(input())
    if json_mode() {
      println(report.to_json().stringify(indent=2))
    } else {
      println("PTP commissioning 0.3.0: " + report.status().label())
      println(report.to_json().stringify(indent=2))
    }
    set_exit(report.exit_code())
    return
  }
  let report = @audit.audit(input())
  if json_mode() {
    println(report.to_json().stringify(indent=2))
  } else {
    println("PTP audit 0.3.0: " + report.status().label())
    for f in report.findings {
      println(
        f.status.label() +
        " " +
        f.rule +
        " frames=" +
        f.frames.map(fn(i) { i.to_string() }).join(",") +
        " expected=" +
        f.expected +
        " actual=" +
        f.actual,
      )
    }
    for m in report.measurements {
      println(
        "offset=" +
        m.offset_numerator +
        "/131072 ns; mean delay=" +
        m.delay_numerator +
        "/131072 ns",
      )
    }
    for explanation in report.metrology {
      println("PTP operand explanation: " + explanation.status.label())
      match explanation.assessment {
        Some(a) =>
          println(
            "CONDITIONAL TIMING LIMIT: " +
            a.verdict +
            "; offset interval=[" +
            a.lower_numerator +
            ", " +
            a.upper_numerator +
            "]/131072 ns; limit=" +
            a.limit_numerator +
            "/131072 ns",
          )
        None =>
          println(
            "Timing limit: not assessed; see supplied evidence and error budget.",
          )
      }
    }
    println(
      "Conditional supported rules only; full IEEE compliance and physical accuracy are not checked.",
    )
  }
  set_exit(report.exit_code())
}
