package UART_RX;

import Clocks :: *;
import GetPut :: *;

import Defs :: *;

interface UART_rx_ifc;
    method Action in_pin(PinState s);
    interface Get#(UART_pkt) data;
endinterface

typedef enum { UartRX_Idle, UartRX_SampleStart, UartRX_SampleData, UartRx_Stop } UartRxState deriving(Eq, Bits);

/*
    UART RX module with 8 data bits, no parity bit and one stop bit.
*/
(* synthesize *)
module mkUART_rx8n1#(Clock dClk, Reset sRst)(UART_rx_ifc);

    Integer sampleMid = valueof(TDiv#(UARTRX_SAMPLE_SIZE, 2));
    Integer sampleTop = valueof(TSub#(UARTRX_SAMPLE_SIZE, 1));
    Integer uartEndIdx = valueof(TSub#(UART_WIDTH, 1));

    SyncFIFOIfc#(UART_pkt) rx_fifo <- mkSyncFIFOFromCC(8, dClk);
    Reg#(PinState) in <- mkReg(tagged HIGH); //pin HIGH in IDLE state 
    Reg#(UartRxState) state <- mkReg(UartRX_Idle);
    Reg#(UInt#(TLog#(UARTRX_SAMPLE_SIZE))) sample_cnt <- mkReg(0);

    Reg#(UInt#(UART_INDEX_WIDTH)) idx <- mkReg('b0);
    Reg#(UART_pkt) recv_pkt <- mkReg('b0);

    SyncBitIfc#(PinState) in_sync <- mkSyncBitToCC(dClk, sRst);

    rule idle (state == UartRX_Idle);
        if(in matches tagged LOW) begin
            state <= UartRX_SampleStart;
        end
    endrule

    rule sampleStart (state == UartRX_SampleStart);
        if(sample_cnt == fromInteger(sampleMid)) begin
            state <= UartRX_SampleData;
            sample_cnt <= 0;
            idx <= 0;
        end 
        else begin
            sample_cnt <= sample_cnt + 1;
        end
    endrule

    rule sampleData (state == UartRX_SampleData);
        let in_bit = pack(in);
        if(sample_cnt == fromInteger(sampleTop)) begin
            let res = {in_bit, recv_pkt[fromInteger(uartEndIdx):1]}; //receiving LSB first
            // recv_pkt[idx] <= in_bit; //MSB first
            recv_pkt <= res; 
            sample_cnt <= 0;
            if(idx == fromInteger(uartEndIdx)) begin
                rx_fifo.enq(unpack(res));
                state <= UartRx_Stop;
            end
            else begin
                idx <= idx + 1;
            end
        end
        else begin
            sample_cnt <= sample_cnt + 1;
        end
    endrule

    rule stop (state == UartRx_Stop);
        if(sample_cnt == fromInteger(sampleTop)) begin
            recv_pkt <= unpack('b0);
            state <= UartRX_Idle;
            sample_cnt <= 0;
        end 
        else begin
            sample_cnt <= sample_cnt + 1;
        end
    endrule


    rule sync_in;
        in <= in_sync.read();
    endrule

    method in_pin(s)    = in_sync.send(s);

    interface data      = toGet(rx_fifo);

endmodule


endpackage