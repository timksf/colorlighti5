package GPOutputPin;

import Clocks :: *;

import Defs :: *;
import SyncBitExtensions :: *;

interface GPOutputPin_ifc;
    (* always_ready *)
    method PinState out();
    method Action set(PinState s);
endinterface


module mkGPOutputPin#(Clock sClk, Reset sRst, parameter PinState defaultState)(GPOutputPin_ifc);

    Reg#(PinState) synced_in <- mkSyncBitInitWrapperToCC(defaultState, sClk, sRst);
    Reg#(PinState) state <- mkReg(defaultState);
    Reg#(PinState) synced_out <- mkSyncBitInitWrapperFromCC(defaultState, sClk);

    rule sync_in;
        state <= synced_in;
    endrule

    rule sync_out;
        synced_out <= state;
    endrule

    method out      = synced_out;
    method set(s)   = action synced_in <= s; endaction;

endmodule

endpackage