// ====================================
// File: uart_tx_and_buffer.v
// Author: jaimebw
// Created: 2025-05-11 20:06:14
// ====================================

module UartTxAndPidBuffer(
    input wire clk,
    input wire rst,
    input wire rx,
    output wire [31:0] a1,
    output wire [31:0] a2,
    output wire test

);


    wire [7:0]  rx_data;
    wire        rx_done;
    wire        rx_busy;

    UartRx #(
        .CLK_FREQ(50_000_000),
        .BAUD_RATE(9600),
        .FRAME_BITS(8)
    ) uart_rx_inst (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .rx_busy(rx_busy)
    );

    // === PID-aware UART Buffer ===
    UartRxPidBuffer rx_pid_buffer (
        .clk(clk),
        .rst(rst),
        .rx_done(rx_done),
        .rx_byte(rx_data),
        .a1(a1),
        .a2(a2),
        .ready(ready),
        .test(test)
    );

endmodule

    
