// ====================================
// File: uart_tx_buffer.v
// Author: jaimebw
// Created: 2025-04-02 23:07:50
// ====================================

module uart_tx_buffer (
    input wire clk,
    input wire reset,
    input wire [31:0] tx_float,      // Float to be sent over UART
    input wire tx_valid,             // Pulse to trigger transmission
    input wire tx_busy,              // UART transmitter busy flag
    output reg [7:0] tx_data,        // Byte to send via uart_tx
    output reg tx_start              // Pulse to trigger uart_tx
);

    reg [1:0] byte_index;
    reg sending;
    reg [31:0] buffer;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_data <= 8'b0;
            tx_start <= 0;
            byte_index <= 0;
            sending <= 0;
            buffer <= 0;
        end else begin
            tx_start <= 0; // default

            if (tx_valid && !sending) begin
                buffer <= tx_float;
                byte_index <= 0;
                sending <= 1;
            end

            if (sending && !tx_busy) begin
                case (byte_index)
                    2'd0: tx_data <= buffer[7:0];
                    2'd1: tx_data <= buffer[15:8];
                    2'd2: tx_data <= buffer[23:16];
                    2'd3: tx_data <= buffer[31:24];
                endcase

                tx_start <= 1;
                byte_index <= byte_index + 1;

                if (byte_index == 2'd3)
                    sending <= 0;
            end
        end
    end

endmodule

