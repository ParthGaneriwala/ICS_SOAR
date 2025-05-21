dtmc

module hardware
// @state_operator_name=apply-opticflow-violated=1
    // State variables
    state_name         : [0..1] init 0 // state_name = hw-cybersickness-monitor
    state_operator_name : [0..1] init 0 // state_operator_name = apply-opticflow-violated
    state_sys-opticflow        : [0..200] init 0;
    state_opticflow-threshold  : [0..200] init 1;
    state_opticflow-counter    : [0..15] init 0;
    state_check-flag           : bool init false;

    // Rule: If state_sys-opticflow < threshold and counter < 15 → increment counter
    [] state_operator_name=0 & state_name=0 & state_sys-opticflow < state_opticflow-threshold & state_opticflow-counter < 15 ->
       0.0((state_opticflow-counter' = state_opticflow-counter + 1) & (state_check-flag' = true)) + 1.0((state_opticflow-counter' = state_opticflow-counter) & (state_check-flag' = false)); // Probability calculated by softmax of 1

endmodule
