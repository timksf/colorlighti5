package Top;

import ECP5_PLL :: *;

interface Top_ifc;
    interface Clock pll_out;
endinterface

module mkTop(Top_ifc);

    Clock clki <- exposeCurrentClock();
    let pll <- mkECP5PLL(clki);

    interface pll_out = pll.clk_0;

endmodule

endpackage