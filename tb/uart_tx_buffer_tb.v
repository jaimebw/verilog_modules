// ====================================
// File: uart_tx_buffer_tb.v
// Author: jaimebw
// Created: 2025-04-02 23:08:24
// ====================================

`timescale 1ns / 1ps

module uart_tx_buffer_tb;

    reg clk;
    reg reset;
    reg [31:0] tx_float;
    reg tx_valid;
    reg tx_busy;
    wire [7:0] tx_data;
    wire tx_start;

    uart_tx_buffer uut (
        .clk(clk),
        .reset(reset),
        .tx_float(tx_float),
        .tx_valid(tx_valid),
        .tx_busy(tx_busy),
        .tx_data(tx_data),
        .tx_start(tx_start)
    );

    // Clock generation
    initial clk = 0;
    always #10 clk = ~clk; // 50MHz clock

    initial begin
        $dumpfile("uart_tx_buffer.vcd");
        $dumpvars(0, uart_tx_buffer_tb);

        // Initialize signals
        reset = 1;
        tx_valid = 0;
        tx_busy = 0;
        tx_float = 32'h00000000;

        #100;
        reset = 0;

        // Send float 0x40400000 = 3.0
        #50;
        tx_float = 32'h40400000;
        tx_valid = 1;
        #20;
        tx_valid = 0;

        // Simulate tx_busy toggling (mimicking UART TX delays)
        repeat (4) begin
            wait (tx_start == 1);
            tx_busy = 1;
            #80;
            tx_busy = 0;
        end

        #200;
        $finish;
    end

endmodule
