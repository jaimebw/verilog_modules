// ====================================
// File: uart_rx.v
// Author: jaimebw
// Created: 2025-05-14 23:12:21
// ====================================

module UartRx#(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 9600,
    parameter FRAME_BITS = 8
)(
    input wire clk,
    input wire rst,
    input wire rx,
    output reg [FRAME_BITS-1:0] rx_data,
    output reg rx_done,
    output reg rx_busy
);

// Internal logic
localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
localparam MID_BIT = CLKS_PER_BIT / 2;
localparam BIT_INDEX_WIDTH = 4;

reg [15:0] clk_count;
reg [BIT_INDEX_WIDTH-1:0] bit_index;
reg [FRAME_BITS-1:0] shift_reg;
reg [1:0] state;

localparam IDLE  = 2'd0,
           START = 2'd1,
           READ  = 2'd2,
           DONE  = 2'd3;

always @(posedge clk or posedge rst) begin
    if (rst) begin
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
                if (rx == 0) begin
                    state <= START;
                    rx_busy <= 1;
                end
            end
            START: begin
                // Muestreo, para asegurarnos que hay una transmision
                if (clk_count == MID_BIT) begin
                    if (rx == 0) begin
                        clk_count <= 0;
                        bit_index <= 0;
                        state <= READ;
                    end else begin
                        state <= IDLE;
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
                    shift_reg[bit_index] <= rx;
                    //bit_index <= bit_index + 1;
                    // if (bit_index == FRAME_BITS - 1) begin
                    //     state <= DONE;
                    // end
                    //
                    if (bit_index == FRAME_BITS - 1) begin
                        state <= DONE;
                    end else begin
                        bit_index <= bit_index + 1;
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

