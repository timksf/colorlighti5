
//simple wrapper module for inverting the locked signal
//so that it can be used as an active LOW reset
module ecp5_pll(
    input clkin,
    output clkout0,
    output clkout1,
    output lockedn
);
    wire locked;
    pll pll_inst(
        .clkin(clkin),
        .clkout0(clkout0),
        .clkout1(clkout1),
        .locked(locked)
    );
    
    assign lockedn = !locked;
endmodule