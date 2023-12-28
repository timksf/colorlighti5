package ECP5_PLL;

interface ECP5_PLL_ifc;
    interface Clock clk_0;
    interface Clock clk_1;

    interface Reset rst_0;
    interface Reset rst_1;
endinterface

import "BVI" ecp5_pll =
module mkECP5PLL#(Clock clk) (ECP5_PLL_ifc);
	default_clock no_clock;
	default_reset no_reset;

	input_clock (clkin) = clk;
	output_clock clk_0(clkout0);
	output_clock clk_1(clkout1);
	output_reset rst_0(lockedn) clocked_by(clk_0);
	output_reset rst_1(lockedn) clocked_by(clk_1);
endmodule 

endpackage