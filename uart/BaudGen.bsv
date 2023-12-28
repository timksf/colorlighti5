package BaudGen;

interface BaudGen_ifc;
    method Bool tick;
    method Action clear;
endinterface

module mkBaudGenerator#(UInt#(16) divisor, UInt#(16) oversampling)(BaudGen_ifc);

    Reg#(UInt#(16)) rCounter <- mkReg(0);
    PulseWire pwTick <- mkPulseWire;
    UInt#(16) top = (divisor / oversampling);

    rule count;
        if(rCounter + 1 >= top) begin
            pwTick.send();
            rCounter <= 0;
        end else begin
            rCounter <= rCounter + 1;
        end
    endrule

    method tick = pwTick;
    method clear = action rCounter <= 0; endaction;


endmodule


endpackage