package UART_TX;

import Clocks :: *;
import GetPut :: *;

import Defs :: *;

interface UART_tx_ifc;
    method PinState out_pin();
    interface Put#(UART_pkt) data;
endinterface

/*
    UART TX module with 8 data bits, no parity bit and one stop bit.
*/
(* synthesize *)
module mkUART_tx8n1#(Clock sClk, Reset sRst)(UART_tx_ifc);
    
    SyncFIFOIfc#(UART_pkt) tx_fifo <- mkSyncFIFOToCC(8, sClk, sRst);
    Reg#(PinState) out <- mkReg(tagged HIGH); //pin HIGH in IDLE state 
    SyncBitIfc#(PinState) out_sync <- mkSyncBitFromCC(sClk);
    Reg#(UInt#(UART_INDEX_WIDTH)) idx <- mkReg(0);
    Reg#(Bool) idle <- mkReg(True);
    Reg#(Bool) stop <- mkReg(False);

    rule stopr (stop);
        //send one stop bit
        out <= tagged HIGH;
        idle <= True;
        stop <= False;
    endrule

    rule send_bit (!stop);
        let pkt = tx_fifo.first;
        //TODO add capability to switch between LSB and MSB first
        let cbit = pkt[fromInteger(valueof(UART_WIDTH) - 1) - idx];
        if(idx == 0 && idle) begin
            //send start bit
            out <= tagged LOW;
            idle <= False;
        end
        else if(idx == fromInteger(valueof(UART_WIDTH) - 1))begin
            tx_fifo.deq;
            //send last bit from current entry in tx_fifo
            out <= unpack(cbit);
            idx <= 0;
            stop <= True;
        end
        else begin
            out <= unpack(cbit);
            idx <= idx + 1;
        end
    endrule

    rule sync_out;
        out_sync.send(out);
    endrule

    method out_pin  = out_sync.read();

    interface data  = toPut(tx_fifo);

endmodule

endpackage