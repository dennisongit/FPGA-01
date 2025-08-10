# FPGA-01

FPGA Development Project - UART Transmitter Module

## Overview

This repository contains a parameterized UART transmitter module implemented in Verilog, along with a comprehensive SystemVerilog testbench for verification.

## Project Structure

```
FPGA-01/
├── README.md          # Project documentation
├── .gitignore         # Git ignore patterns
├── rtl/               # RTL source files
│   └── uart_tx.v      # UART transmitter module
├── sim/               # Simulation and testbench files
│   └── uart_tx_tb.sv  # SystemVerilog testbench
└── scripts/           # Automation scripts
    ├── sim_icarus.sh  # Icarus Verilog simulation script
    └── sim_verilator.sh # Verilator simulation script
```

## Features

- **Parameterized UART TX Module**: Configurable baud rate and data width
- **SystemVerilog Testbench**: Comprehensive verification environment
- **Simulation Scripts**: Ready-to-use scripts for popular open-source simulators
- **Clean Project Structure**: Organized directories for RTL, simulation, and scripts

## Getting Started

### Prerequisites

- Verilog simulator (Icarus Verilog, Verilator, ModelSim, etc.)
- SystemVerilog support for running testbenches

### Running Simulations

#### Using Icarus Verilog
```bash
./scripts/sim_icarus.sh
```

#### Using Verilator
```bash
./scripts/sim_verilator.sh
```

#### Manual Simulation
```bash
# Compile and simulate with your preferred simulator
iverilog -g2012 -o uart_tx_sim rtl/uart_tx.v sim/uart_tx_tb.sv
vvp uart_tx_sim
```

## Module Documentation

### UART Transmitter (`uart_tx.v`)

A parameterized UART transmitter module with the following features:
- Configurable baud rate through clock divider parameter
- Standard UART frame format (start bit, data bits, stop bit)
- Ready/valid handshake interface
- Busy status output

### Testbench (`uart_tx_tb.sv`)

SystemVerilog testbench providing:
- Automated test sequences
- Clock and reset generation
- Data integrity verification
- Timing analysis
- Coverage collection

## License

This project is open source. Feel free to use and modify as needed.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.
