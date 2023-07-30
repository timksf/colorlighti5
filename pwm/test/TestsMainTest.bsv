package TestsMainTest;

    import StmtFSM :: *;
    import TestHelper :: *;
    import PWMGenSingle :: *;

    (* synthesize *)
    module [Module] mkTestsMainTest(TestHelper::TestHandler);

        let dut <- mkPWMGenSingle; 
        let dut2 <- mkPWMGenSingle;

        Stmt s = {
            seq
                action
                    dut.set_duty(50);
                    dut2.set_duty(30);
                endaction
                $display("Starting main PWM test");
                delay(20);
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
