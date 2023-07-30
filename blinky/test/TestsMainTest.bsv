package TestsMainTest;
    import StmtFSM :: *;
    import TestHelper :: *;
    import Blinky :: *;

    (* synthesize *)
    module [Module] mkTestsMainTest(TestHelper::TestHandler);

        Blinky dut <- mkBlinky();

        Stmt s = {
            seq
                $display("Hello World from the testbench.");
                delay(100);
            endseq
        };
        FSM testFSM <- mkFSM(s);

        method Action go();
            testFSM.start();
        endmethod

        method Bool done();
            return testFSM.done();
        endmethod
    endmodule

endpackage
