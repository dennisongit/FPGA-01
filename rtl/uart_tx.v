//=============================================================================
// Title       : UART Transmitter Module
// Project     : FPGA-01 UART Implementation
// File        : uart_tx.v
// Description : Parameterized UART transmitter with configurable baud rate
// Author      : FPGA Development Team
// Created     : August 2025
//=============================================================================

module uart_tx #(
    parameter CLOCK_FREQ = 50_000_000,  // System clock frequency in Hz
    parameter BAUD_RATE  = 115200,      // UART baud rate
    parameter DATA_BITS  = 8            // Number of data bits (5-9)
) (
    input  wire                    clk,        // System clock
    input  wire                    rst_n,      // Active-low reset
    input  wire                    tx_start,   // Start transmission
    input  wire [DATA_BITS-1:0]    tx_data,    // Data to transmit
    output reg                     tx_serial,  // UART serial output
    output wire                    tx_busy,    // Transmission busy flag
    output reg                     tx_done     // Transmission complete
);

    //=========================================================================
    // Local Parameters
    //=========================================================================
    localparam CLKS_PER_BIT = CLOCK_FREQ / BAUD_RATE;
    localparam COUNTER_WIDTH = $clog2(CLKS_PER_BIT);
    
    // State definitions
    localparam [2:0] IDLE       = 3'b000,
                     START_BIT  = 3'b001,
                     DATA_BITS_STATE = 3'b010,
                     STOP_BIT   = 3'b011,
                     CLEANUP    = 3'b100;

    //=========================================================================
    // Internal Signals
    //=========================================================================
    reg [2:0]                  state_reg, state_next;
    reg [COUNTER_WIDTH-1:0]    clk_count_reg, clk_count_next;
    reg [$clog2(DATA_BITS)-1:0] bit_index_reg, bit_index_next;
    reg [DATA_BITS-1:0]        tx_data_reg, tx_data_next;
    reg                        tx_serial_next;
    reg                        tx_done_next;

    //=========================================================================
    // Output Assignments
    //=========================================================================
    assign tx_busy = (state_reg != IDLE);

    //=========================================================================
    // State Machine Registers
    //=========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg     <= IDLE;
            clk_count_reg <= 0;
            bit_index_reg <= 0;
            tx_data_reg   <= 0;
            tx_serial     <= 1'b1;  // UART idle high
            tx_done       <= 1'b0;
        end else begin
            state_reg     <= state_next;
            clk_count_reg <= clk_count_next;
            bit_index_reg <= bit_index_next;
            tx_data_reg   <= tx_data_next;
            tx_serial     <= tx_serial_next;
            tx_done       <= tx_done_next;
        end
    end

    //=========================================================================
    // State Machine Combinational Logic
    //=========================================================================
    always @(*) begin
        // Default assignments
        state_next     = state_reg;
        clk_count_next = clk_count_reg;
        bit_index_next = bit_index_reg;
        tx_data_next   = tx_data_reg;
        tx_serial_next = tx_serial;
        tx_done_next   = 1'b0;

        case (state_reg)
            IDLE: begin
                tx_serial_next = 1'b1;  // Line idle high
                clk_count_next = 0;
                bit_index_next = 0;
                
                if (tx_start) begin
                    tx_data_next = tx_data;
                    state_next = START_BIT;
                end
            end

            START_BIT: begin
                tx_serial_next = 1'b0;  // Start bit is low
                
                if (clk_count_reg < (CLKS_PER_BIT - 1)) begin
                    clk_count_next = clk_count_reg + 1;
                end else begin
                    clk_count_next = 0;
                    state_next = DATA_BITS_STATE;
                end
            end

            DATA_BITS_STATE: begin
                tx_serial_next = tx_data_reg[bit_index_reg];  // LSB first
                
                if (clk_count_reg < (CLKS_PER_BIT - 1)) begin
                    clk_count_next = clk_count_reg + 1;
                end else begin
                    clk_count_next = 0;
                    
                    if (bit_index_reg < (DATA_BITS - 1)) begin
                        bit_index_next = bit_index_reg + 1;
                    end else begin
                        bit_index_next = 0;
                        state_next = STOP_BIT;
                    end
                end
            end

            STOP_BIT: begin
                tx_serial_next = 1'b1;  // Stop bit is high
                
                if (clk_count_reg < (CLKS_PER_BIT - 1)) begin
                    clk_count_next = clk_count_reg + 1;
                end else begin
                    clk_count_next = 0;
                    state_next = CLEANUP;
                end
            end

            CLEANUP: begin
                tx_done_next = 1'b1;
                state_next = IDLE;
            end

            default: begin
                state_next = IDLE;
            end
        endcase
    end

    //=========================================================================
    // Synthesis and Simulation Attributes
    //=========================================================================
    // synthesis translate_off
    initial begin
        $display("UART TX Module Instantiated:");
        $display("  Clock Frequency: %d Hz", CLOCK_FREQ);
        $display("  Baud Rate: %d", BAUD_RATE);
        $display("  Data Bits: %d", DATA_BITS);
        $display("  Clocks per Bit: %d", CLKS_PER_BIT);
        
        if (CLKS_PER_BIT < 16) begin
            $warning("UART TX: Very low clocks per bit (%d). Consider higher clock or lower baud rate.", CLKS_PER_BIT);
        end
    end
    // synthesis translate_on

endmodule

//=============================================================================
// End of File
//=============================================================================
