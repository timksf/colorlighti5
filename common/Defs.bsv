package Defs;

`ifdef BSIM
    typedef 100000 MCLK; //clock frequency in Hz for simulation
    typedef 100 BLINK_INTERVAL; //Interval in micro seconds for simulation
    typedef BLINK_INTERVAL PWM_INTERVAL;
`else
    typedef 25000000 MCLK; //clock frequency in Hz for application
    typedef 1000000 BLINK_INTERVAL; //Interval in micro seconds for application
    typedef 25000 PWM_FREQ; //PWM freq in Hz
    typedef TDiv#(1000000, 25000) PWM_INTERVAL; //PWM interval in micro seconds
`endif


endpackage