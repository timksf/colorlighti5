package PWMGenSingle;

import StmtFSM :: *;
import Assert :: *;
import Real :: *;
import BUtils :: *;

import Defs :: *;

(* always_ready *)
interface PWMGenSingle;
    method Bool pwm_out();
    //set to percentage between 0 and 100
    (*prefix=""*)
    method Action set_duty((*port="duty_in"*)UInt#(8) _);
endinterface

// PWM_INTERVAL x MCLK / 1e6 is #cycles for one pwm period
typedef TDiv#(TMul#(MCLK, PWM_INTERVAL), 1000000) PWM_TIMER_TOP; 
typedef TAdd#(TLog#(PWM_TIMER_TOP), 1) PWM_TIMER_WIDTH;

//Generates PWM signal with output on two different ports and modifiable frequency
(* synthesize *)
module mkPWMGenSingle(PWMGenSingle);

    messageM("PWM timer top: " + integerToString(valueof(PWM_TIMER_TOP)));
    messageM("PWM timer width: " + integerToString(valueof(PWM_TIMER_WIDTH)));

    function UInt#(PWM_TIMER_WIDTH) compareTop(UInt#(8) duty);
        UInt#(32) divisor = 100 / cExtend(duty);
        UInt#(PWM_TIMER_WIDTH) ret = cExtend(fromInteger(valueof(PWM_TIMER_TOP)) / divisor);
        return ret;
    endfunction

    Reg#(UInt#(PWM_TIMER_WIDTH)) timer <- mkReg(0);
    Reg#(Maybe#(UInt#(PWM_TIMER_WIDTH))) duty <- mkReg(tagged Invalid);
    Reg#(Bool) out <- mkReg(False);

    rule pwm (duty matches tagged Valid .d);
        if(timer == fromInteger(valueof(PWM_TIMER_TOP) - 1)) begin
            timer <= 0;
            out <= !out;
        end
        else if(timer == (d - 1)) begin
            out <= !out;
            timer <= timer + 1;
        end
        else begin
            timer <= timer + 1;
        end
    endrule

    //output on two different pins
    method pwm_out      = out._read;

    method set_duty(d) = action
        duty <= tagged Valid compareTop(d);
        timer <= 0;
        out <= True;
    endaction;

endmodule

endpackage
