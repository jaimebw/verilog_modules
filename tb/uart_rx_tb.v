// ====================================
// File: uart_rx_tb.v
// Author: jaimebw
// Created: 2025-04-01 23:28:51
// ====================================
`timescale 1ns / 1ps
module uart_rx_tb;

    parameter CLK_FREQ = 50_000_000;
    parameter BAUD_RATE = 9600;
    parameter FRAME_BITS = 10; // 1 start + 8 data + 1 stop
    parameter DATA_BITS  = 8;

    reg clk;
    reg reset;
    reg rx;
    wire [DATA_BITS-1:0] rx_data;
    wire rx_done;
    wire rx_busy;

    // Instantiate UART RX
    UartRx#(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .FRAME_BITS(FRAME_BITS)
    ) uut (
        .clk(clk),
        .rst(reset),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .rx_busy(rx_busy)
    );

    // Clock generation (50 MHz)
    initial clk = 0;
    always #10 clk = ~clk; // 20 ns period

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // Send UART frame with start(0) + data(Lsb first) + stop(1)
    task send_uart_frame;
        input [7:0] data;
        integer i;
        begin
            // Start bit
            rx = 0;
            repeat (CLKS_PER_BIT) @(posedge clk);

            // Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                repeat (CLKS_PER_BIT) @(posedge clk);
            end

            // Stop bit
            rx = 1;
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    // Wait for rx_done with timeout
    task wait_for_rx_done;
        integer i;
        begin
            for (i = 0; i < CLKS_PER_BIT * 12; i = i + 1) begin
                @(posedge clk);
                if (rx_done) disable wait_for_rx_done;
            end
            $display("❌ Timeout waiting for rx_done");
            $finish;
        end
    endtask

    // Test procedure
    initial begin
        $dumpfile("results/uart_rx.vcd");     
        $dumpvars(0, uart_rx_tb);     

        // Reset
        reset = 1;
        rx = 1; // Idle line high
        repeat (5) @(posedge clk);
        reset = 0;
        repeat (10) @(posedge clk);

        // Test byte 1
        send_uart_frame(8'hAA); // 10101010
        wait_for_rx_done();
        if (rx_data === 8'hAA)
            $display("✅ Test 1 passed: received 0x%h", rx_data);
        else begin
            $display("❌ Test 1 failed: expected 0xAA, got 0x%h", rx_data);
            $finish;
        end

        repeat (CLKS_PER_BIT * 2) @(posedge clk);

        // Test byte 2
        send_uart_frame(8'h55); // 01010101
        wait_for_rx_done();
        if (rx_data === 8'h55)
            $display("✅ Test 2 passed: received 0x%h", rx_data);
        else begin
            $display("❌ Test 2 failed: expected 0x55, got 0x%h", rx_data);
            $finish;
        end

        repeat (CLKS_PER_BIT * 2) @(posedge clk);

        $display("🎉 All tests completed successfully!");
        $finish;
    end

endmodule

