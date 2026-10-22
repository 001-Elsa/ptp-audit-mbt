///|
test "rule coverage EXCHANGE.STATE.RESOURCE guards direct internal replay" {
  // Public audit has a separate earlier EXCHANGE.RESOURCE boundary. This
  // whitebox call verifies the replay's own defensive limit independently.
  let frames = Array::make(257, lifecycle_test_frame(1, @wire.Sync, 10))
  let findings = lifecycle_findings(
    frames,
    [],
    lifecycle_test_context(true, 500),
  )
  assert_eq(findings.length(), 1)
  assert_eq(findings[0].rule, "EXCHANGE.STATE.RESOURCE")
  assert_eq(findings[0].status.label(), "Unsupported")
  assert_eq(findings[0].frames.length(), 0)
  let claims = Array::make(257, ExchangeClaim::{
    sync: 1,
    follow_up: 2,
    delay_req: 3,
    delay_resp: 4,
  })
  let claims_result = lifecycle_findings(
    [],
    claims,
    lifecycle_test_context(true, 500),
  )
  assert_eq(claims_result.length(), 1)
  assert_eq(claims_result[0].rule, "EXCHANGE.STATE.RESOURCE")
  assert_eq(claims_result[0].status.label(), "Unsupported")
}
