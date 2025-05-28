dtmc

module hardware

    // State names
    // 0 = hw_cybersickness_monitor
    // 1 = cybersickness_monitor
    state_name : [0..1] init 0;

    // Operator names
    // 0 = none, 1 = apply_latency_violated, 2 = apply_opticflow_violated, 3 = switch_monitor
    state_operator_name : [0..3] init 1;

    // Variables
    state_io_input_link_systemdata_sys_latency : [0..200] init 35;
    state_latency_threshold : [0..200] init 30;
    state_latency_counter : [0..20] init 0;

    state_sys_opticflow : [0..200] init 0;
    state_opticflow_threshold : [0..200] init 1;
    state_opticflow_counter : [0..15] init 0;

    state_check_flag : bool init false;
   
    // --- Latency violation ---
    [] state_name=0 & state_operator_name=1 & state_io_input_link_systemdata_sys_latency > state_latency_threshold & state_latency_counter < 20 ->
       0.8: (state_latency_counter' = state_latency_counter + 1) & (state_check_flag' = true) +
       0.2: (state_latency_counter' = state_latency_counter) & (state_check_flag' = false);

    // --- Opticflow violation ---
    [] state_name=0 & state_operator_name=2 & state_sys_opticflow < state_opticflow_threshold & state_opticflow_counter < 15 ->
       0.4: (state_opticflow_counter' = state_opticflow_counter + 1) & (state_check_flag' = true) +
       0.6: (state_opticflow_counter' = state_opticflow_counter) & (state_check_flag' = false);

    // --- Mode switch ---
    [] state_name=0 & state_operator_name=3 & state_check_flag = true ->
       0.2: (state_name' = 1) + 0.8: (state_name' = state_name);

endmodule
