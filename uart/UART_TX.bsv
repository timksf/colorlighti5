package UART_TX;

import Clocks :: *;
import GetPut :: *;

import Defs :: *;

import SyncBitExtensions :: *;

interface UART_tx_ifc;
    interface Put#(UART_pkt) data;

    method PinState out_pin();
endinterface

/*
    UART TX module with 8 data bits, no parity bit and a variable number of stop bits.
*/
(* synthesize *)
module mkUART_tx8nN#(Clock sClk, Reset sRst, parameter UInt#(32) stop_bits)(UART_tx_ifc);
    
    SyncFIFOIfc#(UART_pkt) tx_fifo <- mkSyncFIFOToCC(8, sClk, sRst);
    Reg#(PinState) out <- mkSyncBitInitWrapperFromCC(tagged HIGH, sClk); //output pin HIGH in idle state

    Reg#(UInt#(UART_INDEX_WIDTH)) idx <- mkReg(0);

    Reg#(Bool) idle <- mkReg(True);
    Reg#(Bool) stop <- mkReg(False); //start with output pin pulled HIGH

    Reg#(UInt#(32)) rStopCounter <- mkReg(0);

    rule stopr (stop);
        //send stop bits
        out <= tagged HIGH;
        if(rStopCounter == (stop_bits - 1)) begin
            stop <= False;
            idle <= True;
            rStopCounter <= 0;
        end else
            rStopCounter <= rStopCounter + 1;
    endrule

    rule send_bit (!stop && tx_fifo.notEmpty);
        //TODO Maybe add capability to switch between LSB and MSB first
        // let cbit = pkt[fromInteger(valueof(UART_WIDTH) - 1) - idx]; //MSB first
        let pkt = tx_fifo.first;
        let cbit = pkt[idx]; //LSB first
        if(idx == 0 && idle) begin
            //send start bit
            out <= tagged LOW;
            idle <= False;
        end else if(idx == fromInteger(valueof(UART_WIDTH) - 1))begin
            tx_fifo.deq;
            //send last bit from current entry in tx_fifo
            out <= unpack(cbit);
            idx <= 0;
            stop <= True;
        end else begin
            out <= unpack(cbit);
            idx <= idx + 1;
        end
    endrule

    rule rwait (idle && !stop && !tx_fifo.notEmpty);
        out <= tagged HIGH;
    endrule

    method out_pin  = out._read;

    interface data  = toPut(tx_fifo);

endmodule

endpackage