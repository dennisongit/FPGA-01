//=============================================================================
// Title       : UART Transmitter Testbench
// Project     : FPGA-01 UART Implementation
// File        : uart_tx_tb.sv
// Description : SystemVerilog testbench for UART transmitter verification
// Author      : FPGA Development Team
// Created     : August 2025
//=============================================================================

`timescale 1ns / 1ps

module uart_tx_tb;

    //=========================================================================
    // Parameters
    //=========================================================================
    parameter CLOCK_FREQ = 50_000_000;
    parameter BAUD_RATE  = 115200;
    parameter DATA_BITS  = 8;
    parameter CLK_PERIOD = 20;  // 50MHz clock period in ns
    
    localparam CLKS_PER_BIT = CLOCK_FREQ / BAUD_RATE;
    localparam BIT_PERIOD = CLK_PERIOD * CLKS_PER_BIT;  // Time for one UART bit

    //=========================================================================
    // Testbench Signals
    //=========================================================================
    logic                    clk;
    logic                    rst_n;
    logic                    tx_start;
    logic [DATA_BITS-1:0]    tx_data;
    logic                    tx_serial;
    logic                    tx_busy;
    logic                    tx_done;

    //=========================================================================
    // Test Variables
    //=========================================================================
    logic [DATA_BITS-1:0]    test_data_queue[$];
    logic [DATA_BITS-1:0]    expected_data;
    int                      test_count;
    int                      pass_count;
    int                      fail_count;

    //=========================================================================
    // DUT Instantiation
    //=========================================================================
    uart_tx #(
        .CLOCK_FREQ (CLOCK_FREQ),
        .BAUD_RATE  (BAUD_RATE),
        .DATA_BITS  (DATA_BITS)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .tx_start  (tx_start),
        .tx_data   (tx_data),
        .tx_serial (tx_serial),
        .tx_busy   (tx_busy),
        .tx_done   (tx_done)
    );

    //=========================================================================
    // Clock Generation
    //=========================================================================
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    //=========================================================================
    // Reset Task
    //=========================================================================
    task reset_dut();
        $display("[%0t] Resetting DUT...", $time);
        rst_n = 1'b0;
        tx_start = 1'b0;
        tx_data = 8'h00;
        repeat(10) @(posedge clk);
        rst_n = 1'b1;
        repeat(5) @(posedge clk);
        $display("[%0t] Reset complete", $time);
    endtask

    //=========================================================================
    // UART Bit Monitoring Task
    //=========================================================================
    task automatic monitor_uart_transmission(logic [DATA_BITS-1:0] expected);
        logic [DATA_BITS-1:0] received_data = 0;
        int bit_time_error;
        
        $display("[%0t] Monitoring UART transmission, expecting: 0x%02X", $time, expected);
        
        // Wait for start bit
        wait(tx_serial == 1'b0);
        $display("[%0t] Start bit detected", $time);
        
        // Sample at middle of start bit
        #(BIT_PERIOD/2);
        if (tx_serial !== 1'b0) begin
            $error("[%0t] Start bit error: expected 0, got %b", $time, tx_serial);
            fail_count++;
            return;
        end
        
        // Sample data bits (LSB first)
        for (int i = 0; i < DATA_BITS; i++) begin
            #(BIT_PERIOD);
            received_data[i] = tx_serial;
            $display("[%0t] Data bit %0d: %b", $time, i, tx_serial);
        end
        
        // Sample stop bit
        #(BIT_PERIOD);
        if (tx_serial !== 1'b1) begin
            $error("[%0t] Stop bit error: expected 1, got %b", $time, tx_serial);
            fail_count++;
            return;
        end
        $display("[%0t] Stop bit detected", $time);
        
        // Verify received data
        if (received_data === expected) begin
            $display("[%0t] ✓ UART transmission PASSED: 0x%02X", $time, received_data);
            pass_count++;
        end else begin
            $error("[%0t] ✗ UART transmission FAILED: expected 0x%02X, received 0x%02X", 
                   $time, expected, received_data);
            fail_count++;
        end
    endtask

    //=========================================================================
    // UART Transmit Task
    //=========================================================================
    task automatic transmit_byte(logic [DATA_BITS-1:0] data);
        $display("[%0t] Starting transmission of 0x%02X", $time, data);
        
        // Wait for UART to be idle
        wait(!tx_busy);
        
        // Start transmission
        @(posedge clk);
        tx_data = data;
        tx_start = 1'b1;
        
        @(posedge clk);
        tx_start = 1'b0;
        
        // Wait for transmission to complete
        wait(tx_done);
        @(posedge clk);  // Allow done signal to clear
        
        $display("[%0t] Transmission complete", $time);
    endtask

    //=========================================================================
    // Test Scenarios
    //=========================================================================
    
    // Basic transmission test
    task test_basic_transmission();
        $display("\n=== Basic Transmission Test ===");
        test_count++;
        
        fork
            transmit_byte(8'hA5);
            monitor_uart_transmission(8'hA5);
        join
    endtask
    
    // Multiple bytes test
    task test_multiple_bytes();
        $display("\n=== Multiple Bytes Test ===");
        logic [DATA_BITS-1:0] test_bytes[] = '{8'h00, 8'h55, 8'hAA, 8'hFF, 8'h42};
        
        foreach(test_bytes[i]) begin
            test_count++;
            fork
                transmit_byte(test_bytes[i]);
                monitor_uart_transmission(test_bytes[i]);
            join
        end
    endtask
    
    // Back-to-back transmission test
    task test_back_to_back();
        $display("\n=== Back-to-Back Transmission Test ===");
        
        for (int i = 0; i < 3; i++) begin
            test_count++;
            logic [DATA_BITS-1:0] data = $random();
            fork
                transmit_byte(data);
                monitor_uart_transmission(data);
            join
        end
    endtask
    
    // Timing verification test
    task test_timing_verification();
        $display("\n=== Timing Verification Test ===");
        test_count++;
        
        time start_time, bit_time;
        
        // Trigger transmission
        fork
            transmit_byte(8'h96);
        join_none
        
        // Measure timing
        wait(tx_serial == 1'b0);  // Wait for start bit
        start_time = $time;
        
        wait(tx_serial == 1'b1);  // Wait for first data bit
        bit_time = $time - start_time;
        
        if (bit_time == BIT_PERIOD) begin
            $display("[%0t] ✓ Bit timing correct: %0d ns", $time, bit_time);
            pass_count++;
        end else begin
            $error("[%0t] ✗ Bit timing error: expected %0d ns, got %0d ns", 
                   $time, BIT_PERIOD, bit_time);
            fail_count++;
        end
        
        wait(!tx_busy);  // Wait for transmission to complete
    endtask

    //=========================================================================
    // Main Test Sequence
    //=========================================================================
    initial begin
        $display("\n============================================");
        $display("UART Transmitter Testbench Starting");
        $display("============================================");
        $display("Clock Frequency: %0d Hz", CLOCK_FREQ);
        $display("Baud Rate: %0d", BAUD_RATE);
        $display("Data Bits: %0d", DATA_BITS);
        $display("Clocks per Bit: %0d", CLKS_PER_BIT);
        $display("Bit Period: %0d ns", BIT_PERIOD);
        $display("============================================\n");
        
        // Initialize counters
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        // Reset DUT
        reset_dut();
        
        // Run test cases
        test_basic_transmission();
        test_multiple_bytes();
        test_back_to_back();
        test_timing_verification();
        
        // Final reporting
        #1000;
        $display("\n============================================");
        $display("UART Transmitter Testbench Complete");
        $display("============================================");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("\n🎉 ALL TESTS PASSED! 🎉");
        end else begin
            $display("\n❌ SOME TESTS FAILED ❌");
        end
        $display("============================================\n");
        
        $finish;
    end

    //=========================================================================
    // Waveform Dumping
    //=========================================================================
    initial begin
        $dumpfile("uart_tx_tb.vcd");
        $dumpvars(0, uart_tx_tb);
    end

    //=========================================================================
    // Timeout Watchdog
    //=========================================================================
    initial begin
        #50_000_000;  // 50ms timeout
        $error("Testbench timeout!");
        $finish;
    end

endmodule

//=============================================================================
// End of File
//=============================================================================
