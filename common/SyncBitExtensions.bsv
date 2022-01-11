package SyncBitExtensions;

import Clocks :: *;

/* 
    Modified version of the original vSyncBit module, added parameter for initialization 
    of the synchronization registers
*/
import "BVI" SyncBit = 
module vSyncBitInit#(parameter dtype rstVal)
                    (Clock sClkIn, Reset sRstIn, Clock dClkIn, SyncBitIfc#(dtype) ifc)
        provisos(Bits#(dtype, 1));
    default_clock no_clock;
    no_reset;

    parameter init = pack(rstVal);

    input_clock clk_src( sCLK, (*unused*)sCLK_GATE ) = sClkIn;
    input_clock clk_dst( dCLK, (*unused*)dCLK_GATE ) = dClkIn;

    input_reset (sRST) clocked_by (clk_src) = sRstIn ;

    method        send ( sD_IN ) enable(sEN) clocked_by ( clk_src ) reset_by( sRstIn );
    method dD_OUT read()                     clocked_by ( clk_dst ) reset_by( no_reset);

    schedule read CF read;
    schedule read CF send;
    schedule send C  send;
endmodule

module mkSyncBitInit#   (parameter dtype rstVal)
                        (Clock sClkIn, Reset sRstIn,
                         Clock dClkIn,
                         SyncBitIfc#(dtype) ifc)
        provisos(Bits#(dtype, 1));

    SyncBitIfc#(dtype) ifc();
    vSyncBitInit#(rstVal, sClkIn, sRstIn, dClkIn) _SyncBitInit(ifc);

    return ifc;
endmodule

module mkSyncBitInitFromCC# (parameter dtype rstVal)
                            (Clock dClkIn,
                            SyncBitIfc#(dtype) ifc)
        provisos(Bits#(dtype, 1));

    Clock sClk <- exposeCurrentClock;
    Reset sRst <- exposeCurrentReset;

    SyncBitIfc#(dtype) ifc();
    vSyncBitInit#(rstVal, sClk, sRst, dClkIn) _SyncBitInit(ifc);

    return ifc;
endmodule

module mkSyncBitInitToCC# (parameter dtype rstVal)
                            (Clock sClkIn, Reset sRstIn,
                            SyncBitIfc#(dtype) ifc)
        provisos(Bits#(dtype, 1));

    Clock dClk <- exposeCurrentClock;

    SyncBitIfc#(dtype) ifc();
    vSyncBitInit#(rstVal, sClkIn, sRstIn, dClk) _SyncBitInit(ifc);

    return ifc;
endmodule

////////////////////////////////////////////////////////////////////////////////
/// Wrappers for original sync bit modules
////////////////////////////////////////////////////////////////////////////////

/*
    dClk is interpreted as the clock in the destination clock domain
*/
module mkSyncBitWrapperFromCC#(Clock dClk)(Reg#(dtype)) provisos(Bits#(dtype, 1));

    SyncBitIfc#(dtype) sync_out <- mkSyncBitFromCC(dClk);

    method _read        = sync_out.read;
    method _write(d)    = sync_out.send(d);

endmodule

/*
    sClk is interpreted as the clock in the source clock domain
*/
module mkSyncBitWrapperToCC#(Clock sClk, Reset sRst)(Reg#(dtype)) provisos(Bits#(dtype, 1));

    SyncBitIfc#(dtype) sync_in <- mkSyncBitToCC(sClk, sRst);

    method _read        = sync_in.read;
    method _write(d)    = sync_in.send(d);

endmodule

////////////////////////////////////////////////////////////////////////////////
/// Wrappers for sync bit modules with init parameter
////////////////////////////////////////////////////////////////////////////////

/*
    dClk is interpreted as the clock in the destination clock domain
*/
module mkSyncBitInitWrapperFromCC#(parameter dtype init, Clock dClk) (Reg#(dtype)) provisos(Bits#(dtype, 1));

    SyncBitIfc#(dtype) sync_out <- mkSyncBitInitFromCC(init, dClk);

    method _read        = sync_out.read;
    method _write(d)    = sync_out.send(d);

endmodule

/*
    sClk is interpreted as the clock in the source clock domain
*/
module mkSyncBitInitWrapperToCC#(parameter dtype init, Clock sClk, Reset sRst)(Reg#(dtype)) provisos(Bits#(dtype, 1));

    SyncBitIfc#(dtype) sync_in <- mkSyncBitInitToCC(init, sClk, sRst);

    method _read        = sync_in.read;
    method _write(d)    = sync_in.send(d);

endmodule

endpackage