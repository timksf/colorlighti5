package Testbench;

import StmtFSM :: *;

import Blinky :: *;

module mkTestbench(Empty);

    Blink_ifc dut <- mkBlinky;

    Stmt s = seq 
        delay(100); 
    endseq;

    mkAutoFSM(s);

endmodule

endpackage