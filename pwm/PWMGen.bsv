package PWMGen;

import Defs :: *;

interface PWMGen_ifc;
    (* always_ready *)
    method Bool pwm_out();
    (* always_ready *)
    method Bool pwm_out1();
endinterface

typedef TDiv#(TMul#(MCLK, PWM_INTERVAL), 1000000) PWM_TIMER_TOP; 
typedef TLog#(PWM_TIMER_TOP) PWM_TIMER_WIDTH;

//Generates PWM signal with output on two different ports and modifiable frequency
(* synthesize *)
module mkPWMGen(PWMGen_ifc);

    Reg#(UInt#(PWM_TIMER_WIDTH)) _timer <- mkReg(0);
    Reg#(UInt#(PWM_TIMER_WIDTH)) _duty <- mkReg(fromInteger(valueof(TDiv#(PWM_TIMER_TOP, 2))));
    Reg#(Bool) _out <- mkReg(True);

    rule pwm;
        if(_timer == fromInteger(valueof(PWM_TIMER_TOP) - 1)) begin
            _timer <= 0;
            _out <= True;
        end
        else if(_timer == (_duty - 1)) begin
            _out <= False;
            _timer <= _timer + 1;
        end
        else
            _timer <= _timer + 1;
    endrule

    method pwm_out      = _out._read;
    method pwm_out1     = _out._read;
   // method set_duty(d)  = _duty._write(d);

endmodule

endpackage