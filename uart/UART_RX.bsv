package UART_RX;

import Clocks :: *;
import GetPut :: *;

import Defs :: *;

import SyncBitExtensions :: *;

interface UART_rx_ifc;
    method Action in_pin(PinState s);
    interface Get#(UART_pkt) data;

    method PinState input_bit();
endinterface

typedef enum { 
    UART_RX_Idle = 0,
    UART_RX_Data = 1,
    UART_RX_Stop = 2
} UartRxState deriving(Eq, Bits);

/*
    UART RX module with 8 data bits, no parity bit and variable # of stop bits.
*/
(* synthesize *)
module mkUART_rx8n#(Clock dClk, Reset sRst)(UART_rx_ifc);

    Integer sampleStart = valueof(UARTRX_SAMPLE_SIZE)*6/4 -1;
    Integer sampleMid = valueof(TDiv#(UARTRX_SAMPLE_SIZE, 2)) - 1;
    Integer sampleTop = valueof(TSub#(UARTRX_SAMPLE_SIZE, 1));
    Integer uartEndIdx = valueof(TSub#(UART_WIDTH, 1));

    messageM("UART RX sampleMid: " + integerToString(sampleMid));
    messageM("UART RX sampleTop: " + integerToString(sampleTop));

    SyncFIFOIfc#(UART_pkt) rx_fifo <- mkSyncFIFOFromCC(8, dClk);
    Reg#(PinState) in <- mkSyncBitInitWrapperToCC(tagged HIGH, dClk, sRst);

    Reg#(UartRxState) rState <- mkReg(UART_RX_Idle);
    Reg#(UInt#(TAdd#(TLog#(UARTRX_SAMPLE_SIZE), 1))) rSampleCount <- mkReg(0);

    Reg#(UInt#(UART_INDEX_WIDTH)) idx <- mkReg('b0);

    Reg#(Bit#(2)) rRXDebounce <- mkReg(2'b11); //start with 2'b11 as this is the IDLE state
    Reg#(Bit#(2)) rRXDebounceCount <- mkReg(2'b11); //start with 2'b11 as this is the IDLE state
    Reg#(Bit#(1)) rInputBit <- mkReg(1'b1);
    Reg#(UART_pkt) recv_pkt <- mkReg('b0);

    Reg#(PinState) rInputBitDEBUG <- mkSyncBitInitWrapperFromCC(tagged HIGH, dClk);

    rule rdebounce;
        //prevent short spikes from affecting the input
        rRXDebounce <= {rRXDebounce[0], pack(in)};

        //after two 1's this will switch to a 1, after two 0's to a 0
        if(rRXDebounce[1] == 1'b1 && rRXDebounceCount != 2'b11) begin
            rRXDebounceCount <= rRXDebounceCount + 1;
        end else if(rRXDebounce[1] == 1'b0 && rRXDebounceCount != 2'b00) begin
            rRXDebounceCount <= rRXDebounceCount - 1;
        end

        if(rRXDebounceCount == 2'b11) begin
            rInputBit <= 1'b1;
        end else if(rRXDebounceCount == 2'b00) begin
            rInputBit <= 1'b0;
        end
    endrule

    rule fsm;
        case(rState)
            UART_RX_Idle: begin
                let sample_count = rSampleCount;
                if(rInputBit == 1'b0 || rSampleCount != 0) begin
                    sample_count = sample_count + 1;
                end
                if(rSampleCount == fromInteger(sampleStart)) begin 
                    rState <= UART_RX_Data;
                    sample_count = fromInteger(sampleTop);
                    idx <= 0;
                end
                rSampleCount <= sample_count;
            end
            UART_RX_Data: begin
                let sample_count = rSampleCount;
                if(rSampleCount < fromInteger(sampleTop))
                    sample_count = sample_count + 1;
                if(rSampleCount == fromInteger(sampleTop) && idx <= fromInteger(uartEndIdx)) begin
                    //now that we are in the middle of the start bit, sample
                    sample_count = 0;
                    idx <= idx + 1;
                    recv_pkt <= {rInputBit, recv_pkt[fromInteger(uartEndIdx):1]};
                end
                if(idx > fromInteger(uartEndIdx)) begin
                    rState <= UART_RX_Stop;
                    rx_fifo.enq(unpack(recv_pkt));
                end
                rSampleCount <= sample_count;
                end
            UART_RX_Stop: begin
                let sample_count = rSampleCount;
                if(rSampleCount < fromInteger(sampleTop))
                    sample_count = sample_count + 1;
                if(rSampleCount >= fromInteger(sampleTop)) begin
                    sample_count = 0;
                    rState <= UART_RX_Idle;
                    recv_pkt <= 0;
                end
                rSampleCount <= sample_count;
            end
            default: rState <= UART_RX_Idle;
        endcase
    endrule

    // rule fwddebug;
    //     rInputBitDEBUG <= (pack(rState)[0] == 1'b1) ? HIGH : LOW;
    // endrule

    method in_pin(s) = in._write(s);
    method input_bit = rInputBitDEBUG;

    interface data      = toGet(rx_fifo);

endmodule


endpackage