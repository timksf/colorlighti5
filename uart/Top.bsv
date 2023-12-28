package Top;

import ClientServer :: *;
import GetPut :: *;
import StmtFSM :: *;
import List :: *;
import FIFO :: *;
import BRAMFIFO :: *;
import Vector :: *;

import Defs :: *;
import UART :: *;
import FileIO :: *;

module mkSendString#(String text, Put#(Bit#(w)) d)(Stmt);

    Integer ascii_0 = 48;
    Integer ascii_9 = 57;

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

interface Top_ifc;
    (* always_enabled, prefix="" *)
    method Action rx((* port="rx" *)PinState s);
    (* always_ready *)
    method PinState tx();
    (* always_ready, result = "uart_led" *)
    method PinState led();
endinterface

function Bit#(8) charToBit8(Char c) = fromInteger(charToInteger(c));

(* synthesize *)
module mkTop(Top_ifc);
    
    UART_ifc#(8) uart <- mkUART8(BAUD_9600);
    Reg#(Maybe#(Bit#(UART_WIDTH))) rRecv <- mkReg(tagged Invalid);

    let splashText <- mkReadFileStringList("splashscreen.txt");
    function String f(String x, String y) = x+"\n"+y;
    String t = List::fold(f, splashText) + "\n";

    let splashScreenStmt <- mkSendString(t, uart.user.request);
    let splashScreenFSM <- mkFSM(splashScreenStmt);

    Vector#(3, Reg#(Bit#(8))) vCmd <- replicateM(mkRegU);
    Reg#(Bool) done <- mkReg(True);

    rule receive if(done); //if (rRecv matches tagged Invalid &&& splashScreenFSM.done());
        let recv <- uart.user.response.get();
        let newCmd = shiftInAtN(readVReg(vCmd), recv);
        writeVReg(vCmd, newCmd);
        done <= False;
    endrule

    rule process if (splashScreenFSM.done() && !done);
        Bit#(24) cmd = {vCmd[0], vCmd[1], vCmd[2]};
        case(cmd)
            {charToBit8("s"), charToBit8("p"), charToBit8("l")}:
                splashScreenFSM.start();
            // default: 
        endcase
        //invalidate command
        done <= True;
    endrule

    method rx = uart.rx;
    method tx = uart.tx;
    method led = uart.led;

endmodule

endpackage