package UART_TX;

import Clocks :: *;
import GetPut :: *;
import FIFO :: *;
import FIFOF :: *;

import Defs :: *;
import BaudGen :: *;
import SyncBitExtensions :: *;

interface UART_TX_ifc#(numeric type w);
    //hw interface
    method PinState out_pin();

    //user interface
    method Action set_divisor(UInt#(16) d);
    interface Put#(Bit#(w)) data;
endinterface

/*
    UART TX module with 8 data bits, no parity bit and a variable number of rStop bits.
*/
module mkUART_TX#(parameter UInt#(4) stop_bits, parameter UInt#(16) divisor)(UART_TX_ifc#(w));
    
    FIFOF#(Bit#(w)) fTX <- mkSizedFIFOF(1);
    Reg#(PinState) rOutputPin <- mkReg(tagged HIGH);
    Reg#(UInt#(UART_INDEX_WIDTH)) rBitIndex <- mkReg(0);
    Reg#(Bool) rIdle <- mkReg(True);
    Reg#(Bool) rStop <- mkReg(False);
    Reg#(UInt#(4)) rStopCounter <- mkReg(0);

    Reg#(UInt#(16)) rDivisor <- mkReg(divisor);
    Reg#(UInt#(16)) rCLKCount <- mkReg(0);

    //no oversampling -> oversampling rate of 1
    BaudGen_ifc baudGen <- mkBaudGenerator(divisor, 1);

    rule stopr (rStop && baudGen.tick);
        //send rStop bits
        rOutputPin <= tagged HIGH;
        if(rStopCounter == (stop_bits - 1)) begin
            rStop <= False;
            rIdle <= True;
            rStopCounter <= 0;
        end else
            rStopCounter <= rStopCounter + 1;
    endrule

    rule send_bit (!rStop && fTX.notEmpty && baudGen.tick);
        //TODO Maybe add capability to switch between LSB and MSB first
        // let cbit = pkt[fromInteger(valueof(UART_WIDTH) - 1) - rBitIndex]; //MSB first
        let pkt = fTX.first;
        let cbit = pkt[rBitIndex]; //LSB first
        if(rBitIndex == 0 && rIdle) begin
            //send start bit
            rOutputPin <= tagged LOW;
            rIdle <= False;
        end else if(rBitIndex == fromInteger(valueof(UART_WIDTH) - 1))begin
            fTX.deq;
            //send last bit from current entry in tx_fifo
            rOutputPin <= unpack(cbit);
            rBitIndex <= 0;
            rStop <= True;
        end else begin
            rOutputPin <= unpack(cbit);
            rBitIndex <= rBitIndex + 1;
        end
    endrule

    rule rwait (rIdle && !rStop && !fTX.notEmpty);
        rOutputPin <= tagged HIGH;
    endrule

    method out_pin = rOutputPin;

    interface data = toPut(fTX);

endmodule

(* synthesize *)
module mkUART_TX8#(parameter UInt#(4) stop_bits, parameter UInt#(16) divisor)(UART_TX_ifc#(8));

    UART_TX_ifc#(8) ifc();
    mkUART_TX#(stop_bits, divisor) __internal(ifc);

    return ifc;
endmodule

endpackage