// ====================================
// File: uart_tx_tb.v
// Author: jaimebw
// Created: 2025-04-01 23:28:55
// ====================================

`timescale 1ns / 1ps

module uart_tx_tb;

    // Testbench parameters
    parameter CLK_FREQ = 50_000_000;
    parameter BAUD_RATE = 9600;
    parameter FRAME_BITS = 10;

    // Testbench signals
    reg clk;
    reg reset;
    reg [FRAME_BITS-1:0] frame_data;
    reg tx_start;
    wire tx;
    wire tx_busy;
    wire tx_done;

    // Instantiate the UART transmitter
    UartTx#(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .FRAME_BITS(FRAME_BITS)
    ) uut (
        .clk(clk),
        .rst(reset),
        .frame_data(frame_data),
        .tx_start(tx_start),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    // Clock generation
    initial clk = 0;
    always #10 clk = ~clk; // 50 MHz clock => 20ns period

    // Test sequence
    initial begin
        $dumpfile("results/uart_tx.vcd");     
        $dumpvars(0, uart_tx_tb);     
        // Initial values
        reset = 1;
        tx_start = 0;
        frame_data = 10'b0_101110110;

        // Release reset
        #100;
        reset = 0;

        // Wait a bit and start transmission
        #20;
        frame_data = 10'b0_10101111_1; // Example frame: start=0, data=0xAA, stop=1
        tx_start = 1;
        #200;
        tx_start = 0;

        // Wait long enough for transmission to complete
        #1_100_000;

        $finish;
    end

endmodule
