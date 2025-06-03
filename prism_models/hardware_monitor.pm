dtmc

module hardware

  // ============
  // System state
  // ============

  state_name : [0..1] init 0; // 0 = hw_cybersickness_monitor, 1 = cybersickness_monitor
  phase : [0..1] init 0;      // 0 = propose, 1 = apply
  state_operator_name : [0..3] init 0; // 0 = none, 1 = apply_latency_violated, 2 = apply_opticflow_violated, 3 = switch_monitor

  // ============
  // Latency subsystem
  // ============

  state_io_input_link_systemdata_sys_latency : [0..200] init 35;
  state_latency_threshold : [0..200] init 30;
  state_latency_counter : [0..20] init 0;

  // ============
  // Opticflow subsystem
  // ============

  state_sys_opticflow : [0..200] init 0;
  state_opticflow_threshold : [0..200] init 1;
  state_opticflow_counter : [0..15] init 0;

  // ============
  // Flag for mode switch
  // ============

  state_check_flag : bool init false;

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
  [] phase=1 & state_operator_name=1 ->
     0.8 : (state_latency_counter' = min(state_latency_counter + 1, 20)) & (state_check_flag' = true) & (phase' = 0) +
     0.2 : (state_check_flag' = false) & (phase' = 0);

  // Apply opticflow-violated
  [] phase=1 & state_operator_name=2 ->
     0.4 : (state_opticflow_counter' = min(state_opticflow_counter + 1, 15)) & (state_check_flag' = true) & (phase' = 0) +
     0.6 : (state_check_flag' = false) & (phase' = 0);

  // Apply switch-monitor
  [] phase=1 & state_operator_name=3 ->
     0.2 : (state_name' = 1) & (phase' = 0) +
     0.8 : (phase' = 0);

endmodule
