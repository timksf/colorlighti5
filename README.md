# Basic FPGA stuff on colorlight i5 "dev" board

Playing with bluespec/verilog and the ECP5 on a colorlighti5 board
 - Blinky
 - PWM
 - UART
---

## PWM
Two PWM Generators with 50% and 30% duty cycle
![yo](doc/pwm.png)
The PWM design as rendered with `netlistsvg` after generating the netlist with `yosys`:
![PWMGen](https://github.com/timksf/colorlighti5/assets/33375734/1c91671a-f15c-461e-8a5e-4f20449b93f0)

---

## UART
RX and TX modules with customizable Baudrate. <br>
FIFO input to TX module, FIFO output from RX module, depth is customizable. Simple handshaking interfaces for data input/output via bluespec's Put/Get. <br>
Splash screen returned by example top module after receiving "spl":
<!-- ![yo](doc/uart1.png) -->
<!-- ![yo](doc/uart2.PNG) -->
<!-- ![yo](doc/uart3.PNG) -->
![Uart HW Test](doc/uartsplash.png)
(tested on colorlighti5-v7.0)
