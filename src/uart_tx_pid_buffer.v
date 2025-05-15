// ====================================
// File: uart_tx_pid_buffer.v
// Author: jaimebw
// Created: 2025-04-26 19:59:30
// ====================================
module UartTxPidBuffer( 
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] tx_float,     // Word to send over UART
    input  wire        tx_valid,     // Pulse to start transmission
    input  wire        tx_busy,      // UART core busy flag
    input  wire        test,         // Test vs normal PID select
    output reg  [7:0]  tx_data,      // Byte presented to UART
    output reg         tx_start      // Pulse to the UART for each byte
);

    // Frame constants
    localparam START_DEL   = 8'hAA;
    localparam END_DEL     = 8'h55;
    localparam TEST_PID    = 8'h42;
    localparam DATA_PID    = 8'h69;

    // FSM states
    localparam [1:0]
        S_IDLE     = 2'd0,
        S_LOAD     = 2'd1,
        S_WAITBUSY = 2'd2,
        S_WAITFREE = 2'd3;

    reg [1:0]  state;
    reg [2:0]  byte_index;
    reg [31:0] buffer;
    reg        pending_valid;

    // FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state         <= S_IDLE;
            tx_data       <= 8'h00;
            tx_start      <= 1'b0;
            byte_index    <= 3'd0;
            buffer        <= 32'h0;
            pending_valid <= 1'b0;
        end else begin
            // Default: no tx_start unless set in S_LOAD
            tx_start <= 1'b0;

            // Capture tx_valid if busy or not ready
            if (tx_valid && state == S_IDLE && tx_busy)
                pending_valid <= 1'b1;

            case (state)
                S_IDLE: begin
                    if ((tx_valid && !tx_busy) || (pending_valid && !tx_busy)) begin
                        buffer        <= tx_float;
                        byte_index    <= 3'd0;
                        state         <= S_LOAD;
                        pending_valid <= 1'b0; // clear it now that we launch
                    end
                end

                S_LOAD: begin
                    case (byte_index)
                        3'd0: tx_data <= START_DEL;
                        3'd1: tx_data <= test ? TEST_PID : DATA_PID;
                        3'd2: tx_data <= buffer[7:0];
                        3'd3: tx_data <= buffer[15:8];
                        3'd4: tx_data <= buffer[23:16];
                        3'd5: tx_data <= buffer[31:24];
                        3'd6: tx_data <= END_DEL;
                        default: tx_data <= 8'h00;
                    endcase
                    tx_start <= 1'b1;
                    state    <= S_WAITBUSY;
                end

                S_WAITBUSY: begin
                    if (tx_busy) begin
                        tx_start <= 1'b0; // safety
                        state    <= S_WAITFREE;
                    end
                end

                S_WAITFREE: begin
                    if (!tx_busy) begin
                        if (byte_index == 3'd6)
                            state <= S_IDLE;
                        else begin
                            byte_index <= byte_index + 1;
                            state      <= S_LOAD;
                        end
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule

