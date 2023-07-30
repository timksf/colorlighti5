package PWMGen;

import PWMGenSingle :: *;

interface PWMGen;
    (* always_ready *)    
    method Bit#(2) pwm_out;
endinterface

(* synthesize *)
module mkPWMGen(PWMGen);

    let gen1 <- mkPWMGenSingle;
    let gen2 <- mkPWMGenSingle;

    Reg#(Bool) init <- mkReg(False);

    rule rinit (!init);
        gen1.set_duty(30);
        gen2.set_duty(50);
        init <= True;
    endrule

    method pwm_out = { pack(gen1.pwm_out), pack(gen2.pwm_out) };

endmodule

endpackage