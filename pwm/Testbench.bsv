package Testbench;

import StmtFSM :: *;

import PWMGen :: *;

module mkTestbench(Empty);

    PWMGen_ifc dut <- mkPWMGen;

    Stmt s = seq 
        delay(100); 
    endseq;

    mkAutoFSM(s);

endmodule

endpackage