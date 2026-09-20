
# FPGA Vending Machine

An FPGA-based vending-machine controller written in Verilog. The design accepts nickel, dime, and quarter inputs, tracks the current balance, calculates the price of selected products, drives status LEDs, and displays values on a seven-segment display. The final integration also includes a 1 Hz indicator and OLED interface logic.

## Features

- Four selectable products with configurable prices
- Coin input debouncing and synchronization
- Balance tracking with a 95-cent cap
- Automatic vending when sufficient credit is available
- Error indication for invalid product combinations
- Seven-segment amount and cost display
- Verilog testbench for the vending controller
- FPGA pin constraints for the target board

## Repository structure

- `src/` - synthesizable Verilog modules
- `simulation/` - vending-machine testbench
- `constraints/` - FPGA pin constraints

## Main modules

- `vending_machine.v` implements pricing, balance, error, and vending behavior.
- `top_part2.v` integrates the controller, displays, input conditioning, clock indicator, and OLED signals.
- `debounce.v` and `switch_sync.v` condition asynchronous physical inputs.
- `seven_seg.v` drives the four-digit seven-segment display.

## Tools

The project was developed for an FPGA workflow using Verilog and Xilinx Vivado. Add the source and constraint files to a Vivado project, select the correct target board or part, and run simulation before synthesis and implementation.

## Notes

The source code was recovered from the original course submission documents and organized into standard Verilog project files. Board-specific OLED support modules may need to be added to the Vivado project if they were originally supplied separately by the board vendor or course materials.

## Author

Andrew Chong
