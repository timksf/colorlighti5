package Top;

interface Top_ifc;
    (* always_ready *)
    method Bool blink();
endinterface

typedef 25000000 CLK_FREQ; //clock frequency in Hz

typedef 1000 INTERVAL; //Interval in milliseconds

typedef TMul#(TDiv#(CLK_FREQ, INTERVAL), 1000) TIMER_TOP; //timer counts up each cycle, needs top value to toggle led on 

typedef TLog#(TIMER_TOP) TIMER_WIDTH;

// (* no_default_reset *)
module mkTop(Top_ifc);

    Reg#(UInt#(TIMER_WIDTH)) _timer <- mkReg(0);

    Reg#(Bool) _led_out <- mkReg(False);

    rule incr;
        _timer <= _timer + 1;
    endrule

    rule toggle;
        if(_timer == fromInteger(valueof(TIMER_TOP))) begin
            _led_out <= !_led_out;
        end
    endrule

    method blink = _led_out._read;


endmodule

endpackage