dtmc

module hardware

    // State names
    // 0 = hw-cybersickness-monitor
    // 1 = cybersickness-monitor
    state_name         : [0..1] init 0;

    // State Operator names
    // 0 = none, 1 = apply-latency-violated, 2 = apply-opticflow-violated, 3 = switch-monitor
    state_operator_name : [0..3] init 0;

    // Variables
    state_io_input-link_systemdata_sys-latency : [0..200] init 35;
    state_latency-threshold                    : [0..200] init 30;
    state_latency-counter                      : [0..20] init 0;

    state_sys-opticflow        : [0..200] init 0;
    state_opticflow-threshold  : [0..200] init 1;
    state_opticflow-counter    : [0..15] init 0;

    state_check-flag           : bool init false;

    // --- Latency violation ---
    [] state_name=0 & state_operator_name=1 & state_io_input-link_systemdata_sys-latency > state_latency-threshold & state_latency-counter < 20 ->
       0.8:((state_latency-counter' = state_latency-counter + 1) & (state_check-flag' = true)) + 0.2:((state_latency-counter' = state_latency-counter) & (state_check-flag' = false));

    // --- Opticflow violation ---
    [] state_name=0 & state_operator_name=2 & state_sys-opticflow < state_opticflow-threshold & state_opticflow-counter < 15 ->
       0.4:((state_opticflow-counter' = state_opticflow-counter + 1) & (state_check-flag' = true)) + 0.6:((state_opticflow-counter' = state_opticflow-counter) & (state_check-flag' = false));

    // --- Mode switch ---
    [] state_name=0 & state_operator_name=3 & state_check-flag = true ->
       0.2:(state_operator_name' = 1) +  0.8:(state_operator_name' = state_operator_name);

endmodule
