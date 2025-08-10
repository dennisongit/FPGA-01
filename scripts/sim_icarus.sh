#!/bin/bash
#=============================================================================
# Title       : Icarus Verilog Simulation Script
# Project     : FPGA-01 UART Implementation
# File        : sim_icarus.sh
# Description : Automated simulation script for Icarus Verilog
# Author      : FPGA Development Team
# Created     : August 2025
#=============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project paths
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RTL_DIR="$PROJECT_ROOT/rtl"
SIM_DIR="$PROJECT_ROOT/sim"
BUILD_DIR="$PROJECT_ROOT/build"

# Simulation settings
TOP_MODULE="uart_tx_tb"
TIMESCALE="1ns/1ps"
VCD_FILE="uart_tx_simulation.vcd"
EXECUTABLE="uart_tx_sim"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  UART TX Icarus Verilog Simulation${NC}"
echo -e "${BLUE}============================================${NC}"
echo -e "Project Root: $PROJECT_ROOT"
echo -e "RTL Directory: $RTL_DIR"
echo -e "Simulation Directory: $SIM_DIR"
echo -e "Build Directory: $BUILD_DIR"
echo

# Check if Icarus Verilog is installed
if ! command -v iverilog &> /dev/null; then
    echo -e "${RED}Error: Icarus Verilog (iverilog) is not installed or not in PATH${NC}"
    echo -e "${YELLOW}Please install Icarus Verilog:${NC}"
    echo -e "  Ubuntu/Debian: sudo apt install iverilog"
    echo -e "  macOS: brew install icarus-verilog"
    echo -e "  Windows: Download from http://bleyer.org/icarus/"
    exit 1
fi

if ! command -v vvp &> /dev/null; then
    echo -e "${RED}Error: VVP (vvp) is not installed or not in PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Icarus Verilog found: $(iverilog -V | head -1)${NC}"
echo

# Create build directory
echo -e "${YELLOW}Creating build directory...${NC}"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Clean previous build artifacts
echo -e "${YELLOW}Cleaning previous build artifacts...${NC}"
rm -f *.vcd *.lxt *.fst "$EXECUTABLE" *.out

# Check source files exist
echo -e "${YELLOW}Checking source files...${NC}"
if [ ! -f "$RTL_DIR/uart_tx.v" ]; then
    echo -e "${RED}Error: RTL file not found: $RTL_DIR/uart_tx.v${NC}"
    exit 1
fi

if [ ! -f "$SIM_DIR/uart_tx_tb.sv" ]; then
    echo -e "${RED}Error: Testbench file not found: $SIM_DIR/uart_tx_tb.sv${NC}"
    exit 1
fi

echo -e "${GREEN}✓ RTL file found: $RTL_DIR/uart_tx.v${NC}"
echo -e "${GREEN}✓ Testbench file found: $SIM_DIR/uart_tx_tb.sv${NC}"
echo

# Compile with Icarus Verilog
echo -e "${YELLOW}Compiling with Icarus Verilog...${NC}"
echo "Command: iverilog -g2012 -Wall -Winfloop -o $EXECUTABLE -s $TOP_MODULE $RTL_DIR/uart_tx.v $SIM_DIR/uart_tx_tb.sv"

if iverilog -g2012 -Wall -Winfloop -o "$EXECUTABLE" -s "$TOP_MODULE" "$RTL_DIR/uart_tx.v" "$SIM_DIR/uart_tx_tb.sv"; then
    echo -e "${GREEN}✓ Compilation successful${NC}"
else
    echo -e "${RED}✗ Compilation failed${NC}"
    exit 1
fi
echo

# Run simulation
echo -e "${YELLOW}Running simulation...${NC}"
echo "Command: vvp $EXECUTABLE"
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}         Simulation Output${NC}"
echo -e "${BLUE}============================================${NC}"

if vvp "$EXECUTABLE"; then
    echo -e "${BLUE}============================================${NC}"
    echo -e "${GREEN}✓ Simulation completed successfully${NC}"
else
    echo -e "${BLUE}============================================${NC}"
    echo -e "${RED}✗ Simulation failed${NC}"
    exit 1
fi
echo

# Check for VCD file
if [ -f "$VCD_FILE" ]; then
    echo -e "${GREEN}✓ VCD waveform file generated: $VCD_FILE${NC}"
    echo -e "${YELLOW}  To view waveforms, use: gtkwave $VCD_FILE${NC}"
else
    echo -e "${YELLOW}! No VCD file generated${NC}"
fi

# Show build directory contents
echo -e "${YELLOW}Build directory contents:${NC}"
ls -la
echo

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Simulation Script Complete${NC}"
echo -e "${GREEN}============================================${NC}"

exit 0
