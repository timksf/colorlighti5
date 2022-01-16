# Basic FPGA stuff on colorlight i5 "dev" board

Playing with bluespec/verilog and the ECP5 on a colorlighti5 board
## Blink
Blinky with 100us between toggles.
![yo](doc/blinky200us.png)

---

## PWM
Two PWM Generators with 50% and 30% duty cycle
![yo](doc/pwm.png)
### TODO:
1. fix compareTop calculation
2. use compile time duty cycle calculations

---

## UART
RX and TX modules with customizable BAUD rate. <br>
Modules are clocked accordingly. <br>
Uses Bluespec's built-in clock domain crossing functionalities. <br>
FIFO input to TX module, FIFO output from RX module. <br>
RX module has customizable sampling rate.
![yo](doc/uart1.png)
### Pulling from the RX buffer into a recv register:
![yo](doc/uart2.PNG)
### TODO:
1. further simulations
2. HW testing
3. add auto baud in RX module
