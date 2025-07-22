dtmc


// ========= all initialized as global variables =========
global state_name : [0..1] init 0; // 0 = hardware, 1 = cybersickness
global state_operator_name : [0..11] init 0; 
global phase : [0..1] init 0;      // 0 = propose, 1 = apply
global state_latency_counter : [0..3] init 1;
global state_opticflow_counter : [0..3] init 1;
global state_io_input_link_systemdata_sys_latency : [0..200] init 35;
global state_latency_threshold : [0..200] init 30;
global state_sys_opticflow : [0..200] init 0;
global state_opticflow_threshold : [0..200] init 1;
global state_check_flag : bool init false;

global c1 : [0..5] init 4;
global c2 : [0..5] init 4;
global c3 : [0..5] init 4;
global c1x1 : [0..30] init 0;
global c2x2 : [0..15] init 0;
global c3x3 : [0..15] init 0;
global sum : [0..60] init 0;
global c1x1_set : bool init false;
global c2x2_set : bool init false;
global c3x3_set : bool init false;
global sum_weights : bool init false;
global cybersickness_level_checked : bool init false;
global ssq_low    : [0..60] init 30;
global ssq_medium : [0..60] init 40;
global ssq_high   : [0..60] init 60;
global cybersickness_level : [0..2] init 0;
  
module hardware


  // =============
  // Propose phase (decides what to apply)
  // =============

  // Propose latency-violated operator
  [] phase=0 & state_name=0 &
     state_io_input_link_systemdata_sys_latency > state_latency_threshold &
     state_latency_counter < 20 ->
     1.0 : (state_operator_name' = 1) & (phase' = 1);

  // Propose opticflow-violated operator
  [] phase=0 & state_name=0 &
     state_sys_opticflow < state_opticflow_threshold &
     state_opticflow_counter < 15 ->
     1.0 : (state_operator_name' = 2) & (phase' = 1);

  // Propose switch-monitor operator
  [] phase=0 & state_name=0 &
     state_check_flag = true ->
     1.0 : (state_operator_name' = 3) & (phase' = 1);

  // ======================
  // Apply phase (executes operator logic)
  // ======================

  // Apply latency-violated
  [] phase=1 & state_name=0 & state_operator_name=1 ->
     0.731 : (state_latency_counter' = min(state_latency_counter + 1, 3)) & (state_check_flag' = true) & (phase' = 0) +
     0.269 : (state_check_flag' = false) & (phase' = 0);

  // Apply opticflow-violated
  [] phase=1 & state_name=0 & state_operator_name=2 ->
     0.269 : (state_opticflow_counter' = min(state_opticflow_counter + 1, 3)) & (state_check_flag' = true) & (phase' = 0) +
     0.731 : (state_check_flag' = false) & (phase' = 0);

  // Apply switch-monitor
  [] phase=1 & state_name=0 & state_operator_name=3 ->
     1.0 : (state_name' = 1) & (phase' = 0);

endmodule

module cybersickness


  // ====================
  // PROPOSE phase
  // ====================
  [] phase=0 & state_name=1 & !c1x1_set ->
     1.0 : (state_operator_name' = 4) & (phase' = 1);

  [] phase=0 & state_name=1 & !c2x2_set ->
     1.0 : (state_operator_name' = 5) & (phase' = 1);

  [] phase=0 & state_name=1 & !c3x3_set ->
     1.0 : (state_operator_name' = 6) & (phase' = 1);

  [] phase=0 & state_name=1 & c1x1_set & c2x2_set & c3x3_set & !sum_weights ->
     1.0 : (state_operator_name' = 7) & (phase' = 1);

  [] phase=0 & sum_weights & !cybersickness_level_checked & sum < ssq_low ->
     1.0 : (state_operator_name' = 8) & (phase' = 1);

  [] phase=0 & sum_weights & !cybersickness_level_checked & sum >= ssq_low & sum < ssq_medium ->
     1.0 : (state_operator_name' = 9) & (phase' = 1);

  [] phase=0 & sum_weights & !cybersickness_level_checked & sum >= ssq_medium & sum < ssq_high ->
     1.0 : (state_operator_name' = 10) & (phase' = 1);

  [] phase=0 & cybersickness_level_checked ->
     1.0 : (state_operator_name' = 11) & (phase' = 1);

  // ====================
  // APPLY phase
  // ====================
  [] phase=1 & state_name=1 & state_operator_name=4 ->
     1.0 : (c1x1' = c1 * (state_latency_counter + state_opticflow_counter)) &
           (c1x1_set' = true) & (phase' = 0);

  [] phase=1 & state_name=1 & state_operator_name=5 ->
     0.269 : (c2x2' = c2 * state_latency_counter) & (c2x2_set' = true) & (phase' = 0) + 0.731 : (c2x2' = c2x2) & (c2x2_set' = false) & (phase' = 0);

  [] phase=1 & state_name=1 & state_operator_name=6 ->
     0.731 : (c3x3' = c3 * state_opticflow_counter) & (c3x3_set' = true) & (phase' = 0) + 0.269 : (c3x3' = c3x3) & (c3x3_set' = false) & (phase' = 0);

  [] phase=1 & state_name=1 & state_operator_name=7 ->
     1.0 : (sum' = c1x1 + c2x2 + c3x3) &
           (sum_weights' = true) & (phase' = 0);

  [] phase=1 & state_name=1 & state_operator_name=8 ->
     1.0 : (cybersickness_level' = 0) &
           (cybersickness_level_checked' = true) & (phase' = 0);

  [] phase=1 & state_name=1 & state_operator_name=9 ->
     1.0 : (cybersickness_level' = 1) &
           (cybersickness_level_checked' = true) & (phase' = 0);

  [] phase=1 & state_name=1 & state_operator_name=10 ->
     1.0 : (cybersickness_level' = 2) &
           (cybersickness_level_checked' = true) & (phase' = 0);

  [] phase=1 & state_name=1 & state_operator_name=11 ->
     1.0 : (state_name' = 0) &
           (cybersickness_level_checked' = false) &
           (sum_weights' = false) &
           (c1x1_set' = false) &
           (c2x2_set' = false) &
           (c3x3_set' = false) &
           (phase' = 0);

endmodule
