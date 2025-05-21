dtmc

module hardware
// @state_operator_name=apply-latency-violated=1
    // Variables
    state_name         : [0..1] init 0                                      // state_name = hw-cybersickness-monitor
    state_operator_name : [0..1] init 0                                     // state_operator_name = apply-latency-violated
    state_io_input-link_systemdata_sys-latency        : [0..200] init 35;
    state_latency-threshold  : [0..200] init 30;
    state_latency-counter    : [0..20] init 0;
    state_check-flag         : bool init false;

    // If latency is too high and counter < 20, increment the counter
    [] state_operator_name=0 & state_name=0 & state_io_input-link_systemdata_sys-latency > state_latency-threshold & state_latency-counter < 20 ->
       0.3:((latency_counter' = state_latency-counter + 1) & (state_check-flag' = true)) + 0.7:((latency_counter' = state_latency-counter) & (state_check-flag' = false)); // Probability calculated by softmax of 2

    
endmodule
