// ====================================
// File: uart_tx.v
// Author: jaimebw
// Created: 2025-04-01 23:28:17
// ====================================

module uart_tx #(
    parameter CLK_FREQ = 50_000_000,        // System clock frequency in Hz
    parameter BAUD_RATE = 9600,            // Desired baud rate for UART
    parameter FRAME_BITS = 10              // Total bits in the frame (start + data + optional parity + stop)
)(
    input wire clk,                        // System clock
    input wire reset,                      // Asynchronous reset
    input wire [FRAME_BITS-1:0] frame_data,// Full UART frame to transmit
    input wire tx_start,                   // Start transmission signal
    output reg tx,                         // UART TX line
    output reg tx_busy,                    // High when transmitting
    output reg tx_done                     // High for one cycle when done
);

    // Compute clocks per bit based on baud rate
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // Manually set width for bit_index; FRAME_BITS = 10 => 4 bits are enough
    localparam BIT_INDEX_WIDTH = 4;

    reg [15:0] clk_count = 0;  // Counts clock cycles per bit
    reg [BIT_INDEX_WIDTH-1:0] bit_index = 0;  // Tracks bit position in frame
    reg [FRAME_BITS-1:0] tx_shift_reg;        // Shift register holding the frame

    // State machine states
    reg [1:0] state;
    localparam IDLE  = 2'd0,
               TRANS = 2'd1,
               DONE  = 2'd2;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx <= 1'b1;          // Idle state is high
            tx_busy <= 0;
            tx_done <= 0;
            clk_count <= 0;
            bit_index <= 0;
            tx_shift_reg <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    tx_done <= 0;
                    if (tx_start) begin
                        tx_shift_reg <= frame_data;  // Load frame
                        tx_busy <= 1;
                        clk_count <= 0;
                        bit_index <= 0;
                        state <= TRANS;
                    end
                end
                TRANS: begin
                    tx <= tx_shift_reg[bit_index];  // Output current bit
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        bit_index <= bit_index + 1;
                        if (bit_index == FRAME_BITS - 1) begin
                            state <= DONE;
                        end
                    end
                end
                DONE: begin
                    tx <= 1'b1;       // Return to idle high
                    tx_busy <= 0;
                    tx_done <= 1;     // One-cycle done pulse
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
