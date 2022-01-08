package UART;

import FIFO :: *;
import StmtFSM :: *;
import GetPut :: *;
import Clocks :: *;

import Defs :: *;
import StatusLED :: *;
import UART_TX :: *;

interface UART_ifc;
    (* always_ready *)
    method PinState tx();
    (* always_ready *)
    method PinState led();
endinterface

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
    Integer clockDivisor = 2;
    `endif
    return clockDivisor;
endfunction

(* synthesize *)
module mkUART#(parameter Baudrate br)(UART_ifc);

    Integer ascii_0 = 48;
    Integer ascii_9 = 57;

    //uart clock parameters
    Baudrate br = BAUD_9600;
    Integer clockDivisor = divisorFromBR(br);

    //current clock and reset for FIFO synchronization
    Clock currClk <- exposeCurrentClock();
    Reset currRst <- exposeCurrentReset();

    // ------------------- TX ----------------------

    //generate clock and synchronized reset for tx module
    ClockDividerIfc cdiv <- mkClockDivider(clockDivisor);
    Reset rstSync <- mkAsyncResetFromCR(0, cdiv.slowClock);
    UART_tx_ifc my_tx <- mkUART_tx8n1(clocked_by cdiv.slowClock, reset_by rstSync, currClk, currRst);

    Reg#(UInt#(UART_WIDTH)) send_byte <- mkReg(fromInteger(ascii_0));

    // ------------------- RX ----------------------

    //rx module has a higher clock rate than TX module because it needs to sample the input
    Integer clockDivisorRX = clockDivisor / valueOf(UARTRX_SAMPLE_SIZE);
    ClockDividerIfc cdivRX <- mkClockDivider(clockDivisorRX);
    Reset rstSync <- mkAsyncResetFromCR(0, cdivRX.slowClock);
    UART_rx_ifc my_rx <- mkUART_rx8n1(clocked_by cdivRX.slowClock, reset_by rstSy, currClk, currRst);

    //Clock for status LED
    ClockDividerIfc cdivLed <- mkClockDivider(fromInteger(valueof(MCLK)));
    Reset rstSyncLed <- mkAsyncResetFromCR(0, cdivLed.slowClock);
    StatusLEDIfc s_led <- mkStatusLED(clocked_by cdivLed.slowClock, reset_by rstSyncLed, currClk);

    rule incr;    
        if(send_byte == fromInteger(ascii_9))
            send_byte <= fromInteger(ascii_0);
        else 
            send_byte <= send_byte + 1;
    endrule

    rule send; //fill fifo 
        my_tx.data.put('d48);
    endrule

    method tx = my_tx.out_pin;
    method led = s_led.led_out;

endmodule

endpackage