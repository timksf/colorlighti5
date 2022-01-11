package Testbench;

import StmtFSM :: *;

import PWMGen :: *;

module mkTestbench(Empty);

    PWMGen_ifc dut <- mkPWMGen(50);
    PWMGen_ifc dut2 <- mkPWMGen(30);

    Stmt s = seq 
        delay(400); 
    endseq;

    mkAutoFSM(s);

endmodule

endpackage