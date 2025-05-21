dtmc

module hardware
// @state_operator_name=switch-monitor=1
    state_name         : [0..1] init 0                                      // state_name = hw-cybersickness-monitor
    state_operator_name : [0..1] init 0                                     // state_operator_name = switch-monitor
    // state_name: 0 = hw-cybersickness-monitor, 1 = cybersickness-monitor
    state_check-flag  : bool init true;

    // If in hardware mode and state_check-flag is true → switch to cybersickness mode
    [] state_operator_name = 0 & state_check-flag = true ->
       1.0((state_operator_name' = 1));

endmodule
