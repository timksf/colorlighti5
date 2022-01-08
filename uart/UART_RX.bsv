package UART_RX;

import Clocks :: *;
import GetPut :: *;

import Defs :: *;

interface UART_rx_ifc;
    method void in_pin(PinState s);
    interface Get#(UART_pkt) data;
endinterface

typedef enum { UartRX_Idle, UartRX_Sample } UartRxState deriving(Eq, Bits);

/*
    UART RX module with 8 data bits, no parity bit and one stop bit.
*/
(* synthesize *)
module mkUART_rx8n1#(Clock dClk, Reset sRst)(UART_tx_ifc);
    
    SyncFIFOIfc#(UART_pkt) rx_fifo <- mkSyncFIFOFromCC(8, dClk);
    Reg#(PinState) in <- mkReg(tagged HIGH); //pin HIGH in IDLE state 
    Reg#(UartRxState) state <- mkReg(UartRX_Idle);
    Reg#(UInt#(TLog#(UARTRX_SAMPLE_SIZE)) sample_cnt <- mkReg(0);

    SyncBitIfc#(PinState) in_sync <- mkSyncBitToCC(dClk, sRst);

    rule idle (state == UartRX_Idle);
        if(in matches tagged LOW) begin
            state <= UartRX_Sample;
        end
    endrule

    rule sync_in;
        in <= in_sync.read();
    endrule

    method in_pin(s)    = in_sync.send(s);

    interface data      = toGet(rx_fifo);

endmodule


endpackage