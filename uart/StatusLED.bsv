package StatusLED;

import Clocks :: *;

import Defs :: *;

interface StatusLEDIfc;
    (* always_ready *)
    method PinState led_out();
endinterface

(* synthesize *)
module mkStatusLED#(Clock sClk)(StatusLEDIfc);

    SyncBitIfc#(PinState) out_sync <- mkSyncBitFromCC(sClk);
    Reg#(PinState) led <- mkReg(tagged LOW);

    rule toggle;
        if(led matches tagged LOW)
            led <= tagged HIGH;
        else
            led <= tagged LOW;
    endrule

    rule sync;
        out_sync.send(led);
    endrule

    method led_out = out_sync.read();

endmodule


endpackage