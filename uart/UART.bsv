package UART;

import FIFO :: *;
import StmtFSM :: *;
import GetPut :: *;
import Clocks :: *;
import List :: *;

import Defs :: *;
import StatusLED :: *;
import UART_TX :: *;
import UART_RX :: *;
import FileIO :: *;

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

module mkSendString#(String text, Put#(UART_pkt) d)(Stmt);

    Reg#(UInt#(32)) rIndex <- mkRegU;
    let chars = stringToCharList(text);

    Stmt s = seq
        rIndex <= 0;
        while(rIndex < fromInteger(List::length(chars))) action
            Bit#(8) x = fromInteger(charToInteger(chars[rIndex]));
            d.put(unpack(x));
            rIndex <= rIndex + 1;
        endaction
    endseq;

    return s;
endmodule

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

    let splashText <- mkReadFileStringList("splashscreen.txt");
    function String f(String x, String y) = x+"\n"+y;
    String t = fold(f, splashText) + "\n";

    let splashScreenStmt <- mkSendString(t, my_tx.data);
    let splashScreenFSM <- mkFSM(splashScreenStmt);

    rule receive if (rRecv matches tagged Invalid &&& splashScreenFSM.done());
        let recv <- my_rx.data.get();
        rRecv <= tagged Valid recv;
    endrule

    rule process (rRecv matches tagged Valid .pkt);
        if(pack(pkt) == fromInteger(charToInteger("c"))) begin
            splashScreenFSM.start();
        end
        rRecv <= tagged Invalid;
    endrule

    // (* descending_urgency = "mirror_tx, rheartbeat" *)
    // rule mirror_tx if (rRecv matches tagged Valid .pkt);
    //     my_tx.data.put(pkt);
    //     rRecv <= tagged Invalid;
    // endrule

    method rx(s)    = my_rx.in_pin(s);
    method tx       = my_tx.out_pin;
    method led      = s_led.led_out;
    method PinState recv() = my_rx.input_bit;
    
    interface baud = cdiv.slowClock;

endmodule

endpackage