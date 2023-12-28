package StatusLED;

import Defs :: *;
import BaudGen :: *;

module mkPulseGenerator#(UInt#(32) divisor)(BaudGen_ifc);

    Reg#(UInt#(32)) rCounter <- mkReg(0);
    PulseWire pwTick <- mkPulseWire;
    UInt#(32) top = divisor;

    rule count;
        if(rCounter + 1 >= top) begin
            pwTick.send();
            rCounter <= 0;
        end else begin
            rCounter <= rCounter + 1;
        end
    endrule

    method tick = pwTick;
    method clear = action rCounter <= 0; endaction;


endmodule

interface StatusLEDIfc;
    (* always_ready *)
    method PinState led_out();
endinterface

(* synthesize *)
module mkStatusLED#(parameter UInt#(32) divisor)(StatusLEDIfc);
    
    Reg#(PinState) rLED <- mkRegU;
    BaudGen_ifc pulseGen <- mkPulseGenerator(divisor);

    rule toggle if(pulseGen.tick);
        if(rLED matches tagged LOW)
        rLED <= tagged HIGH;
        else
        rLED <= tagged LOW;
    endrule

    method led_out = rLED;

endmodule


endpackage