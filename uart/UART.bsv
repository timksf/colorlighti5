package UART;

import FIFO :: *;
import StmtFSM :: *;
import GetPut :: *;
import Clocks :: *;

import Defs :: *;
import StatusLED :: *;
import UART_TX :: *;
import UART_RX :: *;

interface UART_ifc;
    (* always_ready *)
    method PinState tx();
    (* always_ready, always_enabled, prefix="" *)
    method Action rx((* port="rx" *)PinState s);
    (* always_ready *)
    method PinState led();
    (* always_ready *)
    method PinState recv();
    interface Clock baud;
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
    Integer clockDivisor = 8;
    `endif
    return clockDivisor;
endfunction

/*
    Simple UART mirror
*/
(* synthesize *)
module mkUART(UART_ifc);

    Integer ascii_0 = 48;
    Integer ascii_9 = 57;

    //uart clock parameters
    Baudrate br = BAUD_115200;
    Integer clockDivisor = divisorFromBR(br);

    //current clock and reset for FIFO synchronization
    Clock currClk <- exposeCurrentClock();
    Reset currRst <- exposeCurrentReset();

    // ------------------- TX ----------------------

    //generate clock and synchronized reset for tx module
    ClockDividerIfc cdiv <- mkClockDivider(clockDivisor);
    Reset rstSync <- mkAsyncResetFromCR(0, cdiv.slowClock);
    UART_tx_ifc my_tx <- mkUART_tx8nN(currClk, currRst, 3, clocked_by cdiv.slowClock, reset_by rstSync);

    Reg#(UInt#(UART_WIDTH)) send_byte <- mkReg(fromInteger(ascii_0));

    // ------------------- RX ----------------------

    //rx module has a higher clock rate than TX module because it needs to sample the input
    Integer clockDivisorRX = clockDivisor / valueOf(UARTRX_SAMPLE_SIZE);
    messageM("Clock divisor TX: " + integerToString(clockDivisor));
    messageM("Clock divisor RX: " + integerToString(clockDivisorRX));
    ClockDividerIfc cdivRX <- mkClockDivider(clockDivisorRX);
    Reset rstSyncRX <- mkAsyncResetFromCR(0, cdivRX.slowClock);
    UART_rx_ifc my_rx <- mkUART_rx8n(currClk, currRst, clocked_by cdivRX.slowClock, reset_by rstSyncRX);

    //Clock for status LED
    ClockDividerIfc cdivLed <- mkClockDivider(fromInteger(valueof(MCLK) / 2));
    Reset rstSyncLed <- mkAsyncResetFromCR(0, cdivLed.slowClock);
    StatusLEDIfc s_led <- mkStatusLED(clocked_by cdivLed.slowClock, reset_by rstSyncLed, currClk);

    Integer heartbeat_top = valueof(MCLK) * 2;
    Reg#(Bit#(32)) rUARTHeartBeat <- mkReg(0);

    Reg#(Maybe#(UART_pkt)) rRecv <- mkReg(tagged Invalid);

    rule mirror_rx if (rRecv matches tagged Invalid);
        let recv <- my_rx.data.get();
        rRecv <= tagged Valid recv;
    endrule

    (* descending_urgency = "mirror_tx, rheartbeat" *)
    rule mirror_tx if (rRecv matches tagged Valid .pkt);
        my_tx.data.put(pkt);
        rRecv <= tagged Invalid;
    endrule

    rule rheartbeat;
        if(rUARTHeartBeat >= fromInteger(heartbeat_top)) begin
            rUARTHeartBeat <= 0;
            my_tx.data.put(fromInteger(charToInteger("$")));
        end else
            rUARTHeartBeat <= rUARTHeartBeat + 1;
    endrule 

    // rule send; //fill fifo 
    //     my_tx.data.put(pack(send_byte));

    //     // send_byte <= (send_byte == 48) ? 49 : 48;
    //     //dont put increase in separate rule bc of clock mismatch between this and tx module
    //     if(send_byte >= fromInteger(ascii_9-1) || send_byte < fromInteger(ascii_0))
    //         send_byte <= fromInteger(ascii_0);
    //     else 
    //         send_byte <= send_byte + 1;
    // endrule

    method rx(s)    = my_rx.in_pin(s);
    method tx       = my_tx.out_pin;
    method led      = s_led.led_out;
    method PinState recv() = my_rx.input_bit;
    
    // ;
    //     if(rRecv matches tagged Invalid)
    //         return LOW;
    //     else
    //         return HIGH;
    // endmethod

    interface baud = cdiv.slowClock;

endmodule

endpackage