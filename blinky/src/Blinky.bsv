package Blinky;

import Vector :: *;

interface Blinky;
    (* always_ready *)
    method Bool led_out();
endinterface

typedef 25000000 MCLK;
typedef 250000 BLINK_INTERVAL;

typedef TDiv#(TMul#(MCLK, BLINK_INTERVAL), 1000000) TIMER_TOP;
typedef TLog#(TIMER_TOP) TIMER_WIDTH;

// (* no_default_reset *)
(* synthesize *)
module mkBlinky(Blinky);

    messageM("Counter width: " + integerToString(valueof(TIMER_WIDTH)));

    Reg#(UInt#(TIMER_WIDTH)) timer <- mkReg(0);

    Reg#(Bool) out <- mkReg(False);

    rule incr;
        if(timer == fromInteger(valueof(TIMER_TOP) - 1))
            timer <= 0;
        else
            timer <= timer + 1;
    endrule

    rule toggle;
        if(timer == fromInteger(valueof(TIMER_TOP) - 1)) begin
            out <= !out;
        end
    endrule

    method led_out = out._read;

endmodule

endpackage
