package Blinky;

import Defs :: *;

interface Blink_ifc;
    (* always_ready *)
    method Bool led_out();
endinterface

typedef TDiv#(TMul#(MCLK, BLINK_INTERVAL), 1000000) TIMER_TOP; //timer counts up each cycle, needs top value to toggle led on 

typedef TLog#(TIMER_TOP) TIMER_WIDTH;

// (* no_default_reset *)
(* synthesize *)
module mkBlinky(Blink_ifc);

    Reg#(UInt#(TIMER_WIDTH)) _timer <- mkReg(0);

    Reg#(Bool) _led_out <- mkReg(False);

    rule incr;
        if(_timer == fromInteger(valueof(TIMER_TOP) - 1))
            _timer <= 0;
        else
            _timer <= _timer + 1;
    endrule

    rule toggle;
        if(_timer == fromInteger(valueof(TIMER_TOP) - 1)) begin
            _led_out <= !_led_out;
        end
    endrule

    method led_out = _led_out._read;

endmodule

endpackage