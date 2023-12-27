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

    UART_ifc uart_mod <- mkUART(clocked_by clk, reset_by rst);

    Reg#(UInt#(64)) cnt <- mkReg(0);

    Reg#(UART_pkt) recv <- mkRegU(clocked_by clk, reset_by rst);
    // Reg#(PinState) transmit <- mkRegU(clocked_by clk, reset_by rst);
    Wire#(PinState) bwTxD <- mkBypassWire(clocked_by clk, reset_by rst);

    rule cycle;
        cnt <= cnt + 1;
    endrule

    rule tx_read;
        bwTxD <= uart_mod.tx;
    endrule

    rule rx_emulate;
        uart_mod.rx(LOW);
    endrule

    Stmt s = seq
        par
        seq
            $display("Test");
            delay(500);
            $finish;
        endseq
        endpar
    endseq;

    mkAutoFSM(clocked_by clk, reset_by rst, s);

endmodule

endpackage