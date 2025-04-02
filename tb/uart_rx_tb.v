// ====================================
// File: uart_rx_tb.v
// Author: jaimebw
// Created: 2025-04-01 23:28:51
// ====================================

`timescale 1ns / 1ps

module uart_rx_tb;

    parameter CLK_FREQ = 50_000_000;
    parameter BAUD_RATE = 9600;
    parameter FRAME_BITS = 10;

    reg clk;
    reg reset;
    reg rx;
    wire [FRAME_BITS-1:0] rx_data;
    wire rx_done;
    wire rx_busy;

    // Instantiate UART RX
    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .FRAME_BITS(FRAME_BITS)
    ) uut (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .rx_busy(rx_busy)
    );

    // Clock generation (50 MHz)
    initial clk = 0;
    always #10 clk = ~clk; // 20 ns period

    // Bit timing based on baud rate
    localparam BIT_TIME = 1_000_000_000 / BAUD_RATE; // in ns

    // Stimulus task to send a UART frame
    task send_uart_frame;
        input [FRAME_BITS-1:0] frame;
        integer i;
        begin
            for (i = 0; i < FRAME_BITS; i = i + 1) begin
                rx = frame[i];
                #(BIT_TIME);
            end
        end
    endtask

    // Test procedure
    initial begin
        $dumpfile("results/uart_rx.vcd");     
        $dumpvars(0, uart_rx_tb);     
        // Initial states
        reset = 1;
        rx = 1; // Idle line is high
        #100;
        reset = 0;

        // Wait before sending
        #200;

        // Send a valid frame: start(0), data(0xAA = 10101010), stop(1)
        send_uart_frame(10'b0_10101010_1);

        // Wait long enough to finish
        #200000;

        $finish;
    end

endmodule
