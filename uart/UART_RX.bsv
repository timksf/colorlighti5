package UART_RX;

import Clocks :: *;
import GetPut :: *;
import FIFO :: *;
import FIFOF :: *;
import Assert :: *;

import Defs :: *;
import BaudGen :: *;
import SyncBitExtensions :: *;

interface UART_RX_ifc#(numeric type w);
    //hw interface
    method Action in_pin(PinState s);
    method PinState overflow();
    
    //user interface
    method Action set_divisor(UInt#(16) d);
    interface Get#(Bit#(w)) data;
endinterface

typedef enum { 
    UART_RX_Idle = 0,
    UART_RX_Data = 1
} UartRxState deriving(Eq, Bits);

/*
    UART RX module with 8 data bits, no parity bit and variable # of stop bits.
*/
module mkUART_RX#(parameter UInt#(16) divisor, Integer buffer_size)(UART_RX_ifc#(w))
    provisos(
        Add#(1, a__, w)
    );

    staticAssert(buffer_size <= 8, "Buffer size has to be <= 8");

    Integer uartWidth = valueof(w);
    Integer sampleSize = valueof(UARTRX_SAMPLE_SIZE);
    //sampleStart is used to go from the start bit to the center of first data bit
    Integer sampleStart = (valueof(UARTRX_SAMPLE_SIZE))*6/4 - 1;

    FIFOF#(Bit#(w)) fRX <- mkSizedFIFOF(buffer_size);
    Reg#(PinState) rInputPin <- mkRegU;

    Reg#(UInt#(16)) rDivisor <- mkReg(0);
    Reg#(UartRxState) rState <- mkReg(UART_RX_Idle);
    Reg#(UInt#(16)) rSampleCount <- mkReg(0);
    Reg#(UInt#(TAdd#(TLog#(UART_WIDTH), 1))) rBitIndex <- mkReg(0);
    Reg#(Bit#(w)) rCurrentPkt <- mkReg('b0);
    //start with 2'b11 as this is the IDLE state
    Reg#(Bit#(2)) rRXDebounce <- mkReg(2'b11);
    Reg#(Bit#(2)) rRXDebounceCount <- mkReg(2'b11);
    Reg#(Bit#(1)) rInputBit <- mkReg(1'b1);
    PulseWire pwOverflow <- mkPulseWire;
    
    BaudGen_ifc baudGen <- mkBaudGenerator(divisor, fromInteger(sampleSize));
    Bool sampleTick = baudGen.tick && (rSampleCount == 0);

    rule rdebounce;
        //prevent short spikes from affecting the input
        rRXDebounce <= {rRXDebounce[0], pack(rInputPin)};

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
            UART_RX_Idle: begin //wait for start bit
                if(rInputBit == 1'b0) begin
                    rState <= UART_RX_Data;
                    rSampleCount <= fromInteger(sampleStart);
                end
            end
            UART_RX_Data: begin //sample data bits
                if(sampleTick) begin
                    if(rBitIndex < fromInteger(uartWidth)) begin
                        rBitIndex <= rBitIndex + 1;
                        rCurrentPkt <= {rInputBit, rCurrentPkt[uartWidth-1:1]};
                        rSampleCount <= fromInteger(sampleSize) - 1;
                    end
                    if(rBitIndex >= fromInteger(uartWidth)) begin
                        rState <= UART_RX_Idle;
                        fRX.enq(rCurrentPkt);
                        rSampleCount <= 0;
                        rBitIndex <= 0;
                    end
                    if(rBitIndex >= fromInteger(uartWidth) && !fRX.notFull) begin
                        pwOverflow.send;
                    end
                end else if(baudGen.tick)
                    rSampleCount <= rSampleCount - 1;
            end
            default: rState <= UART_RX_Idle;
        endcase
    endrule

    method in_pin = rInputPin._write;
    method overflow = unpack(pack(pwOverflow));
    interface data = toGet(fRX);

endmodule

(* synthesize *)
module mkUART_RX8#(parameter UInt#(16) divisor)(UART_RX_ifc#(8));

    UART_RX_ifc#(8) ifc();
    mkUART_RX#(divisor, 8) __internal(ifc);

    return ifc;
endmodule


endpackage