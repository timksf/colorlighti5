package Top;

import UART :: *;

(* synthesize *)
module mkTop(UART_ifc);

    UART_ifc uart <- mkUART(BAUD_9600);

    method tx = uart.tx;

endmodule

endpackage