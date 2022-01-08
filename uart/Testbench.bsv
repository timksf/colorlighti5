package Testbench;

import StmtFSM :: *;
import Clocks :: *;
import GetPut :: *;

import Defs :: *;
import UART :: *;
import UART_TX :: *;

module mkTestbench();
    Clock _currClk <- exposeCurrentClock();

    //clock for simulation
    Clock clk <- mkAbsoluteClockFull(1, 1'b1, 1, 1);
    //synchronized reset for simulated module, so we can reset it from the testbench
    Reset rst <- mkInitialReset(1, clocked_by clk);

    //generate clock and synchronized reset for tx module
    ClockDividerIfc cdiv <- mkClockDivider(clocked_by clk, reset_by rst, divisorFromBR(BAUD_9600));
    Reset rstSync <- mkAsyncResetFromCR(0, cdiv.slowClock);

    UART_tx_ifc my_tx <- mkUART_tx8n1(clocked_by cdiv.slowClock, reset_by rstSync, clk, rst);

    Integer ascii_0 = 48;
    Integer ascii_9 = 57;

    Reg#(UInt#(8)) send_byte <- mkRegU(clocked_by clk, reset_by rst);

    Stmt s = seq
        for(send_byte <= fromInteger(ascii_0); send_byte != fromInteger(ascii_9); send_byte <= send_byte + 1) seq
            my_tx.data.put(pack(send_byte));
            delay(100);
        endseq 
        $display("Finishing... ");
        $finish;
    endseq;

    mkAutoFSM(clocked_by clk, reset_by rst, s);

endmodule

endpackage