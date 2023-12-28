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

module mkSendString#(String text, Put#(Bit#(w)) d)(Stmt);

    Reg#(UInt#(32)) rIndex <- mkRegU;
    let chars = stringToCharList(text);

    Stmt s = seq
        rIndex <= 0;
        while(rIndex < fromInteger(List::length(chars))) action
            Bit#(w) x = fromInteger(charToInteger(chars[rIndex]));
            d.put(x);
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
    Baudrate br = BAUD_2400;
    Integer clockDivisor = divisorFromBR(br);

    Reg#(UInt#(UART_WIDTH)) send_byte <- mkReg(fromInteger(ascii_0));

    // ------------------- TX ----------------------
    UART_TX_ifc#(8) my_tx <- mkUART_TX8(3, fromInteger(clockDivisor));
    // ------------------- RX ----------------------
    UART_RX_ifc#(8) my_rx <- mkUART_RX8(fromInteger(clockDivisor));

    messageM("Clock divisor: " + integerToString(clockDivisor));
    messageM("BaudGen top: " + integerToString(clockDivisor / valueof(UARTRX_SAMPLE_SIZE)));

    // ------------------- Status LED -------------------
    StatusLEDIfc s_led <- mkStatusLED(fromInteger(valueof(MCLK) / 4));

    Integer heartbeat_top = valueof(MCLK) * 2;
    Reg#(Bit#(32)) rUARTHeartBeat <- mkReg(0);

    Reg#(Maybe#(Bit#(UART_WIDTH))) rRecv <- mkReg(tagged Invalid);

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
        end else begin
            my_tx.data.put(pkt); //mirror
        end
        rRecv <= tagged Invalid;
    endrule

    let currClk <- exposeCurrentClock;

    method rx(s)    = my_rx.in_pin(s);
    method tx       = my_tx.out_pin;
    method led      = s_led.led_out;
    
    interface baud = currClk;

endmodule

endpackage