// ====================================
// File: UartRxPidBuffer.v
// Author: jaimebw
// Created: 2025-04-06 15:13:34
// ====================================

module UartRxPidBuffer(
    input  wire        clk,
    input  wire        rst,
    input  wire        rx_done,
    input  wire [7:0]  rx_byte,
    output reg  [31:0] a1,
    output reg  [31:0] a2,
    output reg         ready,
    output reg         test
);

    // Frame constants
    localparam TEST_PID    = 8'h69;
    localparam START_FRAME = 8'hAA;
    localparam END_FRAME   = 8'h55;

    // FSM states
    localparam IDLE      = 2'd0;
    localparam GOT_START = 2'd1;
    localparam GOT_PID   = 2'd2;
    localparam GOT_VAL   = 2'd3;

    reg [1:0] state;
    reg [7:0] pid_byte;
    reg [7:0] value_byte;

    reg [7:0] a1_bytes [3:0];
    reg [7:0] a2_bytes [3:0];

    // FSM: handle byte reception
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            pid_byte    <= 8'h00;
            value_byte  <= 8'h00;

            a1_bytes[0] <= 8'h00;
            a1_bytes[1] <= 8'h00;
            a1_bytes[2] <= 8'h00;
            a1_bytes[3] <= 8'h00;

            a2_bytes[0] <= 8'h00;
            a2_bytes[1] <= 8'h00;
            a2_bytes[2] <= 8'h00;
            a2_bytes[3] <= 8'h00;

        end else if (rx_done) begin
            case (state)
                IDLE: begin
                    if (rx_byte == START_FRAME)
                        state <= GOT_START;
                end

                GOT_START: begin
                    pid_byte <= rx_byte;
                    state    <= GOT_PID;
                end

                GOT_PID: begin
                    value_byte <= rx_byte;
                    state      <= GOT_VAL;
                end

                GOT_VAL: begin
                    if (rx_byte == END_FRAME) begin
                        // Commit value to correct position
                        case (pid_byte)
                            8'h10: a1_bytes[3] <= value_byte;
                            8'h11: a1_bytes[2] <= value_byte;
                            8'h12: a1_bytes[1] <= value_byte;
                            8'h13: a1_bytes[0] <= value_byte;
                            8'h20: a2_bytes[3] <= value_byte;
                            8'h21: a2_bytes[2] <= value_byte;
                            8'h22: a2_bytes[1] <= value_byte;
                            8'h23: a2_bytes[0] <= value_byte;
                            TEST_PID: begin
                                a1_bytes[0] <= value_byte;
                                a2_bytes[0] <= value_byte;
                            end
                            default: ; // ignore
                        endcase
                    end
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

    // Output: rebuild a1/a2 and mark ready
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            a1    <= 32'h00000000;
            a2    <= 32'h00000000;
            ready <= 1'b0;
            test  <= 1'b0;
        end else begin
            a1    <= { a1_bytes[3], a1_bytes[2], a1_bytes[1], a1_bytes[0] };
            a2    <= { a2_bytes[3], a2_bytes[2], a2_bytes[1], a2_bytes[0] };
            ready <= 1'b1;
            test  <= (pid_byte == TEST_PID);
        end
    end

endmodule



