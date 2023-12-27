package Testbench;

import StmtFSM :: *;
import Clocks :: *;

import GPOutputPin :: *;
import SyncBitExtensions :: *;
import Defs :: *;

interface PulsePin_ifc;
    interface GPOutputPin_ifc pin;
    // set pulse duration in cycles, clock domain crossing is supported 
    // -> actual duration configurable through clocking
    method Action setPulseDuration(UInt#(16) d);
    method Action pulse();
endinterface

module mkPulsePin#(Clock sClk, Reset sRst, PinState defState)(PulsePin_ifc);

    Reg#(UInt#(16)) sync_in <- mkSyncRegToCC(1, sClk, sRst);//mkSyncBitInitWrapperToCC(1, sClk, sRst);
    Reg#(UInt#(16)) duration <- mkReg(1);
    Reg#(UInt#(16)) cnt <- mkReg(0);
    Reg#(Bool) ready <- mkReg(True);
    
    GPOutputPin_ifc pin_ifc();
    mkGPOutputPin#(sClk, sRst, defState) _internal(pin_ifc);

    rule adv (!ready && cnt > 0);
        cnt <= cnt - 1;
    endrule

    rule end_pulse (!ready && cnt == 0);
        ready <= True;
        pin_ifc.set(defState);
    endrule

    rule sync;
        duration <= sync_in;
    endrule

    interface pin = pin_ifc;
    method setPulseDuration(d) = action sync_in <= d; endaction;
    method pulse if(ready) = 
        action 
            ready <= False;
            cnt <= duration;
            PinState pulseState = 
                case (defState) matches
                    tagged HIGH : return tagged LOW;
                    tagged LOW : return tagged HIGH;
                endcase;
            pin_ifc.set(pulseState);
        endaction;

endmodule


module mkTestbench(Empty);

    Clock _currClk <- exposeCurrentClock();

    //clock for simulation
    Clock clk <- mkAbsoluteClockFull(1, 1'b1, 1, 1);
    //synchronized reset for simulated module, so we can reset it from the testbench
    Reset rst <- mkInitialReset(2, clocked_by clk);

    //clock divider for driving the gpio with its own clock signal
    ClockDividerIfc cdiv <- mkClockDivider(clocked_by clk, reset_by rst, 4);
    Reset rstSync <- mkAsyncReset(0, rst, cdiv.slowClock);

    GPOutputPin_ifc gpout <- mkGPOutputPin(clocked_by cdiv.slowClock, reset_by rstSync, clk, rst, tagged LOW);

    Stmt s = 
    seq 
        delay(10); 
        gpout.set(tagged HIGH);
        delay(10);
        gpout.set(tagged LOW);
        delay(10);
        $display("Test");
    endseq;

    mkAutoFSM(clocked_by clk, reset_by rst, s);

endmodule

endpackage