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
    UartRX_Idle = 5'b00001,
    UartRX_SampleStart = 5'b00010,
    UartRX_SampleData = 5'b00100,
    UartRX_Output = 5'b01000,
    UartRX_Stop = 5'b10000
} UartRxState deriving(Eq, Bits);

/*
    UART RX module with 8 data bits, no parity bit and variable # of stop bits.
*/
(* synthesize *)
module mkUART_rx8n#(Clock dClk, Reset sRst)(UART_rx_ifc);

    Integer sampleMid = valueof(TDiv#(UARTRX_SAMPLE_SIZE, 2)) - 1;
    Integer sampleTop = valueof(TSub#(UARTRX_SAMPLE_SIZE, 1));
    Integer uartEndIdx = valueof(TSub#(UART_WIDTH, 1));

    SyncFIFOIfc#(UART_pkt) rx_fifo <- mkSyncFIFOFromCC(8, dClk);
    Reg#(PinState) in <- mkSyncBitInitWrapperToCC(tagged HIGH, dClk, sRst);

    Reg#(UartRxState) state <- mkReg(UartRX_Idle);
    Reg#(UInt#(TLog#(UARTRX_SAMPLE_SIZE))) rSampleCount <- mkReg(0);

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

    rule idle (state == UartRX_Idle && rInputBit == 1'b0);
        //waits for start bit
        state <= UartRX_SampleStart;
        rSampleCount <= 0;
    endrule

    rule sampleStart (state == UartRX_SampleStart);
        if(rSampleCount == fromInteger(sampleMid)) begin
            //now that we are in the middle of the start bit, move to sampling data
            state <= UartRX_SampleData;
            rSampleCount <= 0;
            idx <= 0;
        end 
        else begin
            //sync with sampling frequency
            //"waits" until half of the start bit is over
            rSampleCount <= rSampleCount + 1;
        end
    endrule

    rule sampleData (state == UartRX_SampleData);
        let in_bit = rInputBit;
        if(rSampleCount == fromInteger(sampleTop)) begin
            let res = {in_bit, recv_pkt[fromInteger(uartEndIdx):1]}; //receiving LSB first
            // recv_pkt[idx] <= in_bit; //MSB first
            recv_pkt <= res; 
            rSampleCount <= 0;
            if(idx == fromInteger(uartEndIdx)) begin
                state <= UartRX_Output;
            end
            else begin
                idx <= idx + 1;
            end
        end
        else begin
            //wait until in the middle of the next bit
            rSampleCount <= rSampleCount + 1;
        end
    endrule

    rule outputData (state == UartRX_Output);
        rx_fifo.enq(unpack(recv_pkt));
        state <= UartRX_Stop;
    endrule

    rule stop (state == UartRX_Stop);
        //count up to make sure the stop bit has started when going back to idle
        if(rSampleCount == fromInteger(sampleTop)) begin
            state <= UartRX_Idle;
            rSampleCount <= 0;
        end 
        else begin
            rSampleCount <= rSampleCount + 1;
        end
    endrule

    rule fwddebug;
        rInputBitDEBUG <= (pack(state)[0] == 1'b1) ? HIGH : LOW;
    endrule

    method in_pin(s) = in._write(s);
    method input_bit = rInputBitDEBUG;

    interface data      = toGet(rx_fifo);

endmodule


endpackage

    // rule fsm;
    //     case(state)
    //         UartRX_Idle: 
    //             if(rInputBit == 1'b0) begin
    //                 state <= UartRX_SampleStart;
    //                 rSampleCount <= 0;
    //             end
    //         UartRX_SampleStart:
    //             if(rSampleCount == fromInteger(sampleMid)) begin
    //                 //now that we are in the middle of the start bit, move to sampling data
    //                 state <= UartRX_SampleData;
    //                 rSampleCount <= 0;
    //                 idx <= 0;
    //             end 
    //             else begin
    //                 //sync with sampling frequency
    //                 //"waits" until half of the start bit is over
    //                 rSampleCount <= rSampleCount + 1;
    //             end
    //         UartRX_SampleData: begin
    //             let in_bit = rInputBit;
    //             if(rSampleCount == fromInteger(sampleTop)) begin
    //                 let res = {in_bit, recv_pkt[fromInteger(uartEndIdx):1]}; //receiving LSB first
    //                 // recv_pkt[idx] <= in_bit; //MSB first
    //                 recv_pkt <= res; 
    //                 rSampleCount <= 0;
    //                 if(idx == fromInteger(uartEndIdx)) begin
    //                     state <= UartRX_Output;
    //                 end
    //                 else begin
    //                     idx <= idx + 1;
    //                 end
    //             end
    //             else begin
    //                 //wait until in the middle of the next bit
    //                 rSampleCount <= rSampleCount + 1;
    //             end
    //         end
    //         UartRX_Output: begin
    //             rx_fifo.enq(unpack(recv_pkt));
    //             state <= UartRX_Stop;
    //         end
    //         UartRX_Stop: 
    //             if(rSampleCount == fromInteger(sampleTop)) begin
    //                 state <= UartRX_Idle;
    //                 rSampleCount <= 0;
    //             end 
    //             else begin
    //                 rSampleCount <= rSampleCount + 1;
    //             end
    //     endcase
    // endrule