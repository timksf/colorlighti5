package TestbenchUARTMirror;

import StmtFSM :: *;
import Clocks :: *;
import GetPut :: *;
import List :: *;

import Defs :: *;
import UART :: *;
import UART_TX :: *;
import UART_RX :: *;
import FileIO :: *;

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
    UART_TX_ifc#(8) my_tx <- mkUART_TX(1, fromInteger(clockDivisor), clocked_by clk, reset_by rst);

    // ------------------- RX ----------------------
    UART_RX_ifc#(8) my_rx <- mkUART_RX(fromInteger(clockDivisor), clocked_by clk, reset_by rst);


    // ------------------- UART MIRROR ----------------------
    //Baudrate is defined inside the module itself for now for easier synthesis
    UART_ifc dut <- mkUART(clocked_by clk, reset_by rst);

    Integer ascii_0 = 48;
    Integer ascii_9 = 57;

    Reg#(Bit#(8)) recv <- mkRegU(clocked_by clk, reset_by rst);

    rule fwd;
        dut.rx(my_tx.out_pin); //simulate input on the RX pin of the UART module 
        my_rx.in_pin(dut.tx); //simulate output from TX pin of the UART module
    endrule

    let splashText <- mkReadFileStringList("splashscreen.txt");
    function String f(String x, String y) = x+"\n"+y;
    String t = fold(f, splashText);

    Stmt s = seq
        par
        // while(True)
        //     action
        //         let r <- my_rx.data.get();
        //         recv <= r;
        //         $display("Received: %0b", r);
        //     endaction
        seq 
            my_tx.data.put('b10111011); //feed data into the standalone TX module
            my_tx.data.put('b10000001); 
            my_tx.data.put('b01010101);
            my_tx.data.put('hAA);
            // my_tx.data.put(fromInteger(charToInteger("c")));
            delay(600); //wait to see results in waveform
            $finish;
        endseq
        endpar
    endseq;

    mkAutoFSM(clocked_by clk, reset_by rst, s);

endmodule

endpackage