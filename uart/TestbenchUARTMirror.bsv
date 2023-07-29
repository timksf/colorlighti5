package TestbenchUARTMirror;

import StmtFSM :: *;
import Clocks :: *;
import GetPut :: *;

import Defs :: *;
import UART :: *;
import UART_TX :: *;
import UART_RX :: *;

module mkTestbenchUARTMirror();
    Clock _currClk <- exposeCurrentClock();

    //clock for simulation
    Clock clk <- mkAbsoluteClockFull(1, 1'b1, 1, 1);
    //synchronized reset for simulated module, so we can reset it from the testbench
    Reset rst <- mkInitialReset(2, clocked_by clk);
    Reset rstRX <- mkInitialReset(4, clocked_by clk); //rx has to wait until output of tx is stable

    Integer clockDivisor = 8;

    // ------------------- TX ----------------------
    //use TX module to send data to mirror module
    //generate clock and synchronized reset for tx module
    ClockDividerIfc cdiv <- mkClockDivider(clocked_by clk, reset_by rst, clockDivisor);
    Reset rstSync <- mkAsyncReset(0, rst, cdiv.slowClock);

    UART_tx_ifc my_tx <- mkUART_tx8n1(clocked_by cdiv.slowClock, reset_by rstSync, clk, rst);

    // ------------------- RX ----------------------
    //receiver module for viewing mirrored data inside this testbench
    Integer clockDivisorRX = clockDivisor / valueOf(UARTRX_SAMPLE_SIZE);
    ClockDividerIfc cdivRX <- mkClockDivider(clocked_by clk, reset_by rstRX, clockDivisorRX);
    Reset rstSyncRX <- mkAsyncReset(0, rstRX, cdivRX.slowClock);
    UART_rx_ifc my_rx <- mkUART_rx8n1(clocked_by cdivRX.slowClock, reset_by rstSyncRX, clk, rstRX);


    // ------------------- UART MIRROR ----------------------
    //Baudrate is defined inside the module itself for now for easier synthesis
    UART_ifc dut <- mkUART(clocked_by clk, reset_by rst);

    Integer ascii_0 = 48;
    Integer ascii_9 = 57;

    Reg#(UART_pkt) recv <- mkRegU(clocked_by clk, reset_by rst);

    Stmt s = seq
        par
        while(True)
            action
                let r <- my_rx.data.get();
                recv <= r;
            endaction
        while(True)
            action
                dut.rx(my_tx.out_pin); //simulate input on the RX pin of the UART module 
                my_rx.in_pin(dut.tx); //simulate output from TX pin of the UART module
            endaction
        seq 
            my_tx.data.put('h41); //feed data into the standalone TX module
            my_tx.data.put('h42); 
            my_tx.data.put('h43); 
            delay(1000);
            $finish;
        endseq
        endpar
    endseq;

    mkAutoFSM(clocked_by clk, reset_by rst, s);

endmodule

endpackage