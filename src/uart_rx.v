// ====================================
// File: uart_rx.v
// Author: jaimebw
// Created: 2025-04-01 23:28:03
// ====================================

module uart_rx #(
    parameter CLK_FREQ = 50_000_000,         // Clock frequency in Hz
    parameter BAUD_RATE = 9600,             // Baud rate
    parameter FRAME_BITS = 10               // Total number of bits (start + data + parity + stop)
)(
    input wire clk,                         // System clock
    input wire reset,                       // Asynchronous reset
    input wire rx,                          // Serial input line
    output reg [FRAME_BITS-1:0] rx_data,    // Received full frame
    output reg rx_done,                     // High for one cycle when reception finishes
    output reg rx_busy                      // High when receiving a frame
);

    // Clock cycles per bit at given baud rate
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam MID_BIT = CLKS_PER_BIT / 2;
    localparam BIT_INDEX_WIDTH = 4; // Manually define width for index (sufficient for FRAME_BITS up to 16)

    reg [15:0] clk_count = 0;
    reg [BIT_INDEX_WIDTH-1:0] bit_index = 0;
    reg [FRAME_BITS-1:0] shift_reg = 0;
    reg [1:0] state;

    localparam IDLE  = 2'd0,
               START = 2'd1,
               READ  = 2'd2,
               DONE  = 2'd3;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_data <= 0;
            rx_done <= 0;
            rx_busy <= 0;
            clk_count <= 0;
            bit_index <= 0;
            shift_reg <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    rx_done <= 0;
                    rx_busy <= 0;
                    clk_count <= 0;
                    bit_index <= 0;
                    if (rx == 0) begin  // Start bit detected (falling edge)
                        state <= START;
                        rx_busy <= 1;
                    end
                end
                START: begin
                    if (clk_count == MID_BIT) begin
                        if (rx == 0) begin  // Still low, valid start bit
                            clk_count <= 0;
                            bit_index <= 0;
                            state <= READ;
                        end else begin
                            state <= IDLE;  // False start
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                READ: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        shift_reg[bit_index] <= rx;  // Sample bit
                        bit_index <= bit_index + 1;
                        if (bit_index == FRAME_BITS - 1) begin
                            state <= DONE;
                        end
                    end
                end
                DONE: begin
                    rx_data <= shift_reg;
                    rx_done <= 1;
                    rx_busy <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

