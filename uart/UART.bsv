package UART;

import FIFO :: *;
import StmtFSM :: *;
import GetPut :: *;
import Clocks :: *;
import List :: *;
import ClientServer :: *;

import Defs :: *;
import StatusLED :: *;
import UART_TX :: *;
import UART_RX :: *;
import FileIO :: *;

interface UART_ifc#(numeric type w);
    (* always_ready *)
    method PinState tx();
    (* always_enabled, prefix="" *)
    method Action rx((* port="rx" *)PinState s);
    (* always_ready *)
    method PinState led();
    (* always_ready *)
    method PinState recv();
    //user interface
    interface Server#(Bit#(w), Bit#(w)) user;
endinterface

/*
    Simple UART module
*/
(* synthesize *)
module mkUART8#(parameter Baudrate br)(UART_ifc#(8));

    function Integer divisorFromBR(Baudrate br);
        `ifndef BSIM
        Integer clockDivisor = 
            case (br)
                BAUD_2400:      return valueof(TDiv#( MCLK,   2400 ));
                BAUD_4800:      return valueof(TDiv#( MCLK,   4800 ));
                BAUD_9600:      return valueof(TDiv#( MCLK,   9600 ));
                BAUD_57600:     return valueof(TDiv#( MCLK,  57600 ));
                BAUD_115200:    return valueof(TDiv#( MCLK, 115200 ));
                BAUD_230400:    return valueof(TDiv#( MCLK, 230400 ));
            endcase;
        `else
        Integer clockDivisor = 8;
        `endif
        return clockDivisor;
    endfunction

    // Baudrate br = BAUD_2400;
    Integer clockDivisor = divisorFromBR(br);

    // ------------------- TX ----------------------
    UART_TX_ifc#(8) uart_tx <- mkUART_TX8(3, fromInteger(clockDivisor));
    // ------------------- RX ----------------------
    UART_RX_ifc#(8) uart_rx <- mkUART_RX8(fromInteger(clockDivisor));

    // messageM("Clock divisor: " + integerToString(clockDivisor));
    // messageM("BaudGen top: " + integerToString(clockDivisor / valueof(UARTRX_SAMPLE_SIZE)));

    // ------------------- Status LED -------------------
    StatusLEDIfc s_led <- mkStatusLED(fromInteger(valueof(MCLK) / 4));

    let currClk <- exposeCurrentClock;

    method rx = uart_rx.in_pin;
    method tx = uart_tx.out_pin;
    method led = s_led.led_out;
    
    interface user = toGPServer(uart_tx.data, uart_rx.data);

endmodule

endpackage