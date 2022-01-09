package Testbench;

import StmtFSM :: *;
import Clocks :: *;
import GetPut :: *;

import Defs :: *;
import UART :: *;
import UART_TX :: *;
import UART_RX :: *;

module mkTestbench();
    Clock _currClk <- exposeCurrentClock();

    //clock for simulation
    Clock clk <- mkAbsoluteClockFull(1, 1'b1, 1, 1);
    //synchronized reset for simulated module, so we can reset it from the testbench
    Reset rst <- mkInitialReset(2, clocked_by clk);
    Reset rstRX <- mkInitialReset(4, clocked_by clk); //rx has to wait until output of tx is stable

    Integer clockDivisor = 8;

    // ------------------- TX ----------------------
    //generate clock and synchronized reset for tx module
    ClockDividerIfc cdiv <- mkClockDivider(clocked_by clk, reset_by rst, clockDivisor);
    Reset rstSync <- mkAsyncReset(0, rst, cdiv.slowClock);

    UART_tx_ifc my_tx <- mkUART_tx8n1(clocked_by cdiv.slowClock, reset_by rstSync, clk, rst);

    // ------------------- RX ----------------------
    Integer clockDivisorRX = clockDivisor / valueOf(UARTRX_SAMPLE_SIZE);
    ClockDividerIfc cdivRX <- mkClockDivider(clocked_by clk, reset_by rstRX, clockDivisorRX);
    Reset rstSyncRX <- mkAsyncReset(0, rstRX, cdivRX.slowClock);
    UART_rx_ifc my_rx <- mkUART_rx8n1(clocked_by cdivRX.slowClock, reset_by rstSyncRX, clk, rstRX);

    Integer ascii_0 = 48;
    Integer ascii_9 = 57;

    Reg#(UInt#(8)) send_byte <- mkReg(clocked_by clk, reset_by rst, fromInteger(ascii_0));

    Reg#(Bool) start_rx <- mkReg(False);

    rule fwd;
        my_rx.in_pin(my_tx.out_pin);
    endrule

    Stmt s = seq
        par
        seq
        $display("rx divisor: %d", clockDivisorRX);
        $display("Testing UART modules");
        // for(send_byte <= fromInteger(ascii_0); send_byte != fromInteger(ascii_9); send_byte <= send_byte + 1) seq
        //     my_tx.data.put(pack(send_byte));
        //     delay(100);
        // endseq
        my_tx.data.put(pack(send_byte)); 
        delay(100);
        $display("Done... ");
        delay(100);
        $finish;
        endseq
        endpar
    endseq;

    mkAutoFSM(clocked_by clk, reset_by rst, s);

endmodule

endpackage