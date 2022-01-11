package PWMGen;

import StmtFSM :: *;
import Assert :: *;
import Real :: *;

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
module mkPWMGen#(parameter UInt#(8) duty_cycle)(PWMGen_ifc);

    staticAssert(0 <= duty_cycle && 100 >= duty_cycle, "Use integer from 0 to 100 (duty cycle in percent");

    UInt#(8) divisor = 100 / duty_cycle;
    UInt#(PWM_TIMER_WIDTH) compareTop = truncate(fromInteger(valueof(PWM_TIMER_TOP)) / divisor);

    // mkAutoFSM(seq 
    //     $display("Divisor: %d", divisor);
    //     $display("CompareTop: %d", compareTop);
    // endseq);

    // Integer compareTop = floor()

    Reg#(UInt#(PWM_TIMER_WIDTH)) timer <- mkReg(0);
    //just use ~50% duty cycle for now
    Reg#(UInt#(PWM_TIMER_WIDTH)) duty <- mkReg(compareTop); //fromInteger(valueof(TDiv#(PWM_TIMER_TOP, 2)))
    Reg#(Bool) out <- mkReg(True);

    rule pwm;
        if(timer == fromInteger(valueof(PWM_TIMER_TOP) - 1)) begin
            timer <= 0;
            out <= True;
        end
        else if(timer == (duty - 1)) begin
            out <= False;
            timer <= timer + 1;
        end
        else
            timer <= timer + 1;
    endrule

    //output on two different pins
    method pwm_out      = out._read;
    method pwm_out1     = out._read;

endmodule

endpackage