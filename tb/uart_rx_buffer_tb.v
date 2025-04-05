// ====================================
// File: uart_rx_buffer_tb.v
// Author: jaimebw
// Created: 2025-04-02 23:01:40
// ====================================

`timescale 1ns / 1ps

module uart_rx_buffer_tb;

    reg clk;
    reg reset;
    reg rx_done;
    reg [7:0] rx_byte;
    wire [31:0] rx_float;
    wire rx_valid;

    // Instantiate the module
    uart_rx_buffer uut (
        .clk(clk),
        .reset(reset),
        .rx_done(rx_done),
        .rx_byte(rx_byte),
        .rx_float(rx_float),
        .rx_valid(rx_valid)
    );

    // Clock generation (50 MHz)
    initial clk = 0;
    always #10 clk = ~clk; // 20ns period

    // Test procedure
    initial begin
        $dumpfile("results/uart_rx_buffer.vcd");
        $dumpvars(0, uart_rx_buffer_tb);

        // Initial conditions
        reset = 1;
        rx_done = 0;
        rx_byte = 0;
        #100;
        reset = 0;

        // Send 4 bytes representing 32-bit float 0x3F800000 = 1.0
        #50 send_byte(8'h00); // LSB first
        #50 send_byte(8'h00);
        #50 send_byte(8'h80);
        #50 send_byte(8'h3F); // MSB

        // Wait and finish
        #100;
        $finish;
    end

    // Task to simulate byte arrival
    task send_byte;
        input [7:0] byte_in;
        begin
            rx_byte = byte_in;
            rx_done = 1;
            #20;
            rx_done = 0;
        end
    endtask

endmodule
