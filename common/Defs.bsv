package Defs;

`ifdef BSIM
    typedef 100000 MCLK; //clock frequency in Hz for simulation

    //blinky
    typedef 100 BLINK_INTERVAL; //Interval in micro seconds for simulation

    //pwm
    typedef BLINK_INTERVAL PWM_INTERVAL;
`else
    typedef 25000000 MCLK; //clock frequency in Hz for application

    //blinky
    typedef 100000 BLINK_INTERVAL; //Interval in micro seconds for application

    //pwm
    typedef 25000 PWM_FREQ; //PWM freq in Hz
    typedef TDiv#(1000000, 25000) PWM_INTERVAL; //PWM interval in micro seconds
`endif

typedef union tagged {
    void LOW;
    void HIGH;
}PinState deriving(Bits, Eq);

typedef enum { BAUD_2400, BAUD_4800, BAUD_9600, BAUD_57600, BAUD_115200, BAUD_230400 } Baudrate deriving(Bits, Eq);

typedef 8 UART_WIDTH;
typedef Bit#(UART_WIDTH) UART_pkt;
typedef TLog#(UART_WIDTH) UART_INDEX_WIDTH;
typedef 16 UARTRX_SAMPLE_SIZE;



endpackage