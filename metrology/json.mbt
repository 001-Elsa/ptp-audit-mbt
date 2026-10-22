///|
pub fn ErrorBudget::to_json(self : ErrorBudget) -> Json {
  Json::object({
    "timestamp_error_bounds_scaled": Json::array(
      self.timestamp_error_bounds_scaled.map(Json::string),
    ),
    "timestamp_order": Json::array(["t1", "t2", "t3", "t4"].map(Json::string)),
    "correction_error_bound_scaled": Json::string(
      self.correction_error_bound_scaled,
    ),
    "path_asymmetry_bound_scaled": Json::string(
      self.path_asymmetry_bound_scaled,
    ),
    "offset_limit_scaled": Json::string(self.offset_limit_scaled),
    "source": Json::string(self.source),
    "assumptions": Json::string(self.assumptions),
    "relative_rate_bound_confirmed": Json::boolean(
      self.relative_rate_bound_confirmed,
    ),
    "scaled_nanoseconds_denominator": Json::number(65536),
  })
}

///|
pub fn CorrectionContribution::to_json(self : CorrectionContribution) -> Json {
  Json::object({
    "frame": Json::number(self.frame.to_double()),
    "field": Json::string(self.field),
    "correction_scaled": Json::string(self.correction_scaled),
    "offset_numerator": Json::string(self.offset_numerator),
    "delay_numerator": Json::string(self.delay_numerator),
    "included": Json::boolean(self.included),
    "denominator": Json::number(131072),
  })
}

///|
pub fn CorrectionLedger::to_json(self : CorrectionLedger) -> Json {
  Json::object({
    "uncorrected_offset_numerator": Json::string(
      self.uncorrected_offset_numerator,
    ),
    "uncorrected_delay_numerator": Json::string(
      self.uncorrected_delay_numerator,
    ),
    "corrected_offset_numerator": Json::string(self.corrected_offset_numerator),
    "corrected_delay_numerator": Json::string(self.corrected_delay_numerator),
    "denominator": Json::number(self.denominator.to_double()),
    "unit": Json::string("ns"),
    "forward_raw_scaled": Json::string(self.forward_raw_scaled),
    "reverse_raw_scaled": Json::string(self.reverse_raw_scaled),
    "contributions": Json::array(
      self.contributions.map(CorrectionContribution::to_json),
    ),
    "invariants": Json::object({
      "offset": Json::string(
        "corrected_offset = uncorrected_offset - Sync.c - Follow_Up.c + Delay_Resp.c (numerators over 131072 ns)",
      ),
      "mean_delay": Json::string(
        "corrected_delay = uncorrected_delay - Sync.c - Follow_Up.c - Delay_Resp.c (numerators over 131072 ns)",
      ),
      "delay_request": Json::string(
        "Delay_Req.correctionField is excluded: the Delay_Resp correction is the delay-path operand and is not subtracted twice.",
      ),
    }),
  })
}

///|
pub fn Assessment::to_json(self : Assessment) -> Json {
  Json::object({
    "verdict": Json::string(self.verdict),
    "lower_numerator": Json::string(self.lower_numerator),
    "upper_numerator": Json::string(self.upper_numerator),
    "radius_numerator": Json::string(self.radius_numerator),
    "limit_numerator": Json::string(self.limit_numerator),
    "denominator": Json::number(self.denominator.to_double()),
    "unit": Json::string("ns"),
    "budget": self.budget.to_json(),
    "radius_formula": Json::string(
      "radius_numerator = u_t1 + u_t2 + u_t3 + u_t4 + aggregate_correction_error + abs_forward_minus_reverse_path_delay_bound",
    ),
    "limit_formula": Json::string("limit_numerator = 2 * offset_limit_scaled"),
    "classification": Json::string(
      "within_limit: abs(center)+radius<=limit; outside_limit: lower>limit or upper<(-limit); otherwise indeterminate. Limits are inclusive.",
    ),
    "scope": Json::string(
      "A conditional interval for slave-minus-master offset. This does not infer path asymmetry, authenticate calibration, prove hardware accuracy or establish IEEE conformance.",
    ),
  })
}

///|
pub fn Explanation::to_json(self : Explanation) -> Json {
  Json::object({
    "frames": Json::array(
      self.frames.map(fn(id) { Json::number(id.to_double()) }),
    ),
    "status": Json::string(self.status.label()),
    "detail": Json::string(self.detail),
    "ledger": match self.ledger {
      Some(value) => value.to_json()
      None => Json::null()
    },
    "assessment": match self.assessment {
      Some(value) => value.to_json()
      None => Json::null()
    },
    "assessment_state": Json::string(
      match self.assessment {
        Some(_) => "conditionally_assessed"
        None => "not_assessed"
      },
    ),
  })
}
