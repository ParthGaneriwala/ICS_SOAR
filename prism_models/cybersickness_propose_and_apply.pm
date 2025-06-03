dtmc

module cybersickness

  // States
  state_name : [0..1] init 1; // 0 = hw-cybersickness-monitor, 1 = cybersickness-monitor

  // Operator states
  // 1 = apply-c1x1
  // 2 = apply-c2x2
  // 3 = apply-c3x3
  // 4 = apply-sum-weights
  // 5 = apply-normal-cybersickness-level
  // 6 = apply-affected-cybersickness-level
  // 7 = apply-incapacitated-cybersickness-level
  // 8 = switch-monitor
  state_operator_name : [0..8] init 1;

  // Inputs & constants
  state_latency_counter : [0..20] init 5;
  state_opticflow_counter : [0..15] init 3;
  c1 : [0..1000] init 59;  // 0.59 * 100
  c2 : [0..1000] init 30;  // 0.30 * 100
  c3 : [0..1000] init 13;  // 0.013 * 100

  // Computed weights
  c1x1 : [0..2000] init 0;
  c2x2 : [0..2000] init 0;
  c3x3 : [0..2000] init 0;
  sum : [0..10000] init 0;

  // Set flags
  c1x1_set : bool init false;
  c2x2_set : bool init false;
  c3x3_set : bool init false;
  sum_weights : bool init false;
  cybersickness_level_checked : bool init false;

  // SSQ thresholds (scaled by 100)
  ssq_low : [0..10000] init 400;
  ssq_medium : [0..10000] init 600;
  ssq_high : [0..10000] init 900;

  // Cybersickness levels
  cybersickness_level : [0..2] init 0; // 0 = not-affected, 1 = affected, 2 = incapacitated

  // Apply c1x1 = c1 * (latency + opticflow)
  [] state_operator_name = 1 & !c1x1_set ->
     1.0 : (c1x1' = c1 * (latency_counter + opticflow_counter)) & (c1x1_set' = true);

  // Apply c2x2 = c2 * latency
  [] state_operator_name = 2 & !c2x2_set ->
     1.0 : (c2x2' = c2 * latency_counter) & (c2x2_set' = true);

  // Apply c3x3 = c3 * opticflow
  [] state_operator_name = 3 & !c3x3_set ->
     1.0 : (c3x3' = c3 * opticflow_counter) & (c3x3_set' = true);

  // Sum = c1x1 + c2x2 + c3x3
  [] state_operator_name = 4 & c1x1_set & c2x2_set & c3x3_set & !sum_weights ->
     1.0 : (sum' = c1x1 + c2x2 + c3x3) & (sum_weights' = true);

  // Normal level
  [] state_operator_name = 5 & sum_weights & !cybersickness_level_checked & sum < ssq_low ->
     1.0 : (cybersickness_level' = 0) & (cybersickness_level_checked' = true);

  // Affected level
  [] state_operator_name = 6 & sum_weights & !cybersickness_level_checked & sum >= ssq_low & sum < ssq_medium ->
     1.0 : (cybersickness_level' = 1) & (cybersickness_level_checked' = true);

  // Incapacitated level
  [] state_operator_name = 7 & sum_weights & !cybersickness_level_checked & sum >= ssq_medium & sum < ssq_high ->
     1.0 : (cybersickness_level' = 2) & (cybersickness_level_checked' = true);

  // Switch back to HW monitor
  [] state_operator_name = 8 & cybersickness_level_checked ->
     1.0 : (state_name' = 0)
           & (cybersickness_level_checked' = false)
           & (sum_weights' = false)
           & (c1x1_set' = false)
           & (c2x2_set' = false)
           & (c3x3_set' = false);

endmodule
