dtmc

module cybersickness

  // ====================
  // State and Control
  // ====================
  state_name : [0..1] init 1;     // 0 = hw-cybersickness-monitor, 1 = cybersickness-monitor
  phase : [0..1] init 0;          // 0 = propose, 1 = apply
  state_operator_name : [0..8] init 0; // 0 = none, 1–8 = apply-* operators

  // ====================
  // Inputs & Constants
  // ====================
  state_latency_counter : [0..20] init 5;
  state_opticflow_counter : [0..15] init 3;

  c1 : [0..1000] init 59;   // 0.59 * 100
  c2 : [0..1000] init 30;   // 0.30 * 100
  c3 : [0..1000] init 13;   // 0.013 * 100

  // ====================
  // Computed Weights
  // ====================
  c1x1 : [0..2000] init 0;
  c2x2 : [0..2000] init 0;
  c3x3 : [0..2000] init 0;
  sum : [0..10000] init 0;

  // ====================
  // State Flags
  // ====================
  c1x1_set : bool init false;
  c2x2_set : bool init false;
  c3x3_set : bool init false;
  sum_weights : bool init false;
  cybersickness_level_checked : bool init false;

  // ====================
  // SSQ Thresholds
  // ====================
  ssq_low    : [0..10000] init 400;
  ssq_medium : [0..10000] init 600;
  ssq_high   : [0..10000] init 900;

  cybersickness_level : [0..2] init 0; // 0 = not-affected, 1 = affected, 2 = incapacitated

  // ====================
  // PROPOSE phase
  // ====================
  [] phase=0 & state_name=1 & !c1x1_set ->
     1.0 : (state_operator_name' = 1) & (phase' = 1);

  [] phase=0 & state_name=1 & !c2x2_set ->
     1.0 : (state_operator_name' = 2) & (phase' = 1);

  [] phase=0 & state_name=1 & !c3x3_set ->
     1.0 : (state_operator_name' = 3) & (phase' = 1);

  [] phase=0 & state_name=1 & c1x1_set & c2x2_set & c3x3_set & !sum_weights ->
     1.0 : (state_operator_name' = 4) & (phase' = 1);

  [] phase=0 & sum_weights & !cybersickness_level_checked & sum < ssq_low ->
     1.0 : (state_operator_name' = 5) & (phase' = 1);

  [] phase=0 & sum_weights & !cybersickness_level_checked & sum >= ssq_low & sum < ssq_medium ->
     1.0 : (state_operator_name' = 6) & (phase' = 1);

  [] phase=0 & sum_weights & !cybersickness_level_checked & sum >= ssq_medium & sum < ssq_high ->
     1.0 : (state_operator_name' = 7) & (phase' = 1);

  [] phase=0 & cybersickness_level_checked ->
     1.0 : (state_operator_name' = 8) & (phase' = 1);

  // ====================
  // APPLY phase
  // ====================

  [] phase=1 & state_operator_name=1 ->
     1.0 : (c1x1' = c1 * (state_latency_counter + state_opticflow_counter)) &
           (c1x1_set' = true) & (phase' = 0);

  [] phase=1 & state_operator_name=2 ->
     1.0 : (c2x2' = c2 * state_latency_counter) &
           (c2x2_set' = true) & (phase' = 0);

  [] phase=1 & state_operator_name=3 ->
     1.0 : (c3x3' = c3 * state_opticflow_counter) &
           (c3x3_set' = true) & (phase' = 0);

  [] phase=1 & state_operator_name=4 ->
     1.0 : (sum' = c1x1 + c2x2 + c3x3) &
           (sum_weights' = true) & (phase' = 0);

  [] phase=1 & state_operator_name=5 ->
     1.0 : (cybersickness_level' = 0) &
           (cybersickness_level_checked' = true) & (phase' = 0);

  [] phase=1 & state_operator_name=6 ->
     1.0 : (cybersickness_level' = 1) &
           (cybersickness_level_checked' = true) & (phase' = 0);

  [] phase=1 & state_operator_name=7 ->
     1.0 : (cybersickness_level' = 2) &
           (cybersickness_level_checked' = true) & (phase' = 0);

  [] phase=1 & state_operator_name=8 ->
     1.0 : (state_name' = 0) &
           (cybersickness_level_checked' = false) &
           (sum_weights' = false) &
           (c1x1_set' = false) &
           (c2x2_set' = false) &
           (c3x3_set' = false) &
           (phase' = 0);

endmodule
