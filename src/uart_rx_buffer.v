// ====================================
// File: uart_rx_buffer.v
// Author: jaimebw
// Created: 2025-04-02 22:57:20
// ====================================

module UartRxBuffer(
    input wire clk,
    input wire rst,
    input wire rx_done,              // Pulse from uart_rx when a byte is received
    input wire [7:0] rx_byte,        // Received byte from uart_rx
    output reg [31:0] rx_float,      // Assembled 32-bit float
    output reg rx_valid              // Goes high for 1 cycle when full float is ready
);

    reg [1:0] byte_count;            // Counts from 0 to 3
    reg [31:0] buffer;               // Temporary storage for 4 bytes

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            byte_count <= 0;
            buffer <= 0;
            rx_float <= 0;
            rx_valid <= 0;
        end else begin
            rx_valid <= 0; // default: deassert unless triggered below

            if (rx_done) begin
                case (byte_count)
                    2'd0: buffer[7:0]   <= rx_byte;
                    2'd1: buffer[15:8]  <= rx_byte;
                    2'd2: buffer[23:16] <= rx_byte;
                    2'd3: begin
                        buffer[31:24] <= rx_byte;
                        rx_float <= {rx_byte, buffer[23:0]};
                        rx_valid <= 1;
                    end
                endcase

                byte_count <= byte_count + 1;
            end
        end
    end

endmodule

