// // ====================================
// // File: UartRxPidBuffer.v
// // Author: jaimebw
// // Created: 2025-04-06 15:13:34
// // ====================================

// module UartRxPidBuffer(
//     input  wire        clk,
//     input  wire        rst,
//     input  wire        rx_done,
//     input  wire [7:0]  rx_byte,
//     output reg  [31:0] a1,
//     output reg  [31:0] a2,
//     output reg         ready,
//     output reg         test
// );

//     // Frame constants
//     localparam TEST_PID    = 8'h69;
//     localparam START_FRAME = 8'hAA;
//     localparam END_FRAME   = 8'h55;

//     // FSM states
//     localparam IDLE      = 2'd0;
//     localparam GOT_START = 2'd1;
//     localparam GOT_PID   = 2'd2;
//     localparam GOT_VAL   = 2'd3;

//     reg [1:0] state;
//     reg [7:0] pid_byte;
//     reg [7:0] value_byte;

//     reg [7:0] a1_bytes [3:0];
//     reg [7:0] a2_bytes [3:0];
//     reg set_ready;

//     // FSM: handle byte reception
//     always @(posedge clk or posedge rst) begin
//         if (rst) begin
//             state       <= IDLE;
//             pid_byte    <= 8'h00;
//             value_byte  <= 8'h00;

//             a1_bytes[0] <= 8'h00;
//             a1_bytes[1] <= 8'h00;
//             a1_bytes[2] <= 8'h00;
//             a1_bytes[3] <= 8'h00;

//             a2_bytes[0] <= 8'h00;
//             a2_bytes[1] <= 8'h00;
//             a2_bytes[2] <= 8'h00;
//             a2_bytes[3] <= 8'h00;

//         end else if (rx_done) begin
//             case (state)
//                 IDLE: begin
//                     if (rx_byte == START_FRAME)
//                         state <= GOT_START;
//                 end

//                 GOT_START: begin
//                     pid_byte <= rx_byte;
//                     state    <= GOT_PID;
//                 end

//                 GOT_PID: begin
//                     value_byte <= rx_byte;
//                     state      <= GOT_VAL;
//                 end

//                 GOT_VAL: begin
//                     if (rx_byte == END_FRAME) begin
//                         // Commit value to correct position
//                         case (pid_byte)
//                             8'h10: a1_bytes[3] <= value_byte;
//                             8'h11: a1_bytes[2] <= value_byte;
//                             8'h12: a1_bytes[1] <= value_byte;
//                             8'h13: a1_bytes[0] <= value_byte;
//                             8'h20: a2_bytes[3] <= value_byte;
//                             8'h21: a2_bytes[2] <= value_byte;
//                             8'h22: a2_bytes[1] <= value_byte;
//                             8'h23: a2_bytes[0] <= value_byte;
//                             TEST_PID: begin
//                                 a1_bytes[0] <= value_byte;
//                                 a2_bytes[0] <= value_byte;
//                             end
//                             default: ; // ignore
//                         endcase
//                     set_ready <= 1'b1; 
//                     end
//                     state <= IDLE;
//                 end

//                 default: state <= IDLE;
//             endcase
//         end
//     end
//     always @(posedge clk or posedge rst) begin
//         if (rst) begin
//             a1        <= 32'h00000000;
//             a2        <= 32'h00000000;
//             ready     <= 1'b0;
//             test      <= 1'b0;
//             set_ready <= 1'b0;
//         end else begin
//             if (set_ready) begin
//                 a1    <= { a1_bytes[3], a1_bytes[2], a1_bytes[1], a1_bytes[0] };
//                 a2    <= { a2_bytes[3], a2_bytes[2], a2_bytes[1], a2_bytes[0] };
//                 ready <= 1'b1;
//             end else begin
//                 ready <= 1'b0;
//             end

//             test <= (pid_byte == TEST_PID);
//             set_ready <= 1'b0;  // default
//         end
//     end


// endmodule


// ====================================
// File: UartRxPidBuffer.v
// Author: jaimebw
// Created: 2025-04-06 15:13:34
// ====================================

// ====================================
// File: UartRxPidBuffer.v
// Author: jaimebw
// Updated: 2025-05-14 with full a1/a2 frame check
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
    localparam GOT_START = 2'd1;   // got start delimiter, expect PID
    localparam GOT_PID   = 2'd2;   // got PID, expect VALUE
    localparam GOT_VAL   = 2'd3;   // got VALUE, expect END

    reg [1:0] state;
    reg [7:0] pid_byte;
    reg [7:0] value_byte;

    reg [7:0] a1_bytes [3:0];
    reg [7:0] a2_bytes [3:0];

    reg [3:0] a1_written;
    reg [3:0] a2_written;

    reg set_ready;
    reg set_ready_ff;

    //------------------------------------------------------------------
    // Byte-reception state machine
    //------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            pid_byte     <= 8'h00;
            value_byte   <= 8'h00;
            a1_bytes[0]  <= 8'h00; a1_bytes[1] <= 8'h00;
            a1_bytes[2]  <= 8'h00; a1_bytes[3] <= 8'h00;
            a2_bytes[0]  <= 8'h00; a2_bytes[1] <= 8'h00;
            a2_bytes[2]  <= 8'h00; a2_bytes[3] <= 8'h00;
            a1_written   <= 4'b0;
            a2_written   <= 4'b0;
            set_ready    <= 1'b0;
        end else begin
            set_ready <= 1'b0;                      // default each cycle

            if (rx_done) begin
                case (state)
                    //--------------------------------------------------
                    IDLE:       if (rx_byte == START_FRAME)
                                     state <= GOT_START;

                    //--------------------------------------------------
                    GOT_START:  begin
                                    pid_byte <= rx_byte; // latch PID
                                    state    <= GOT_PID;
                                 end

                    //--------------------------------------------------
                    GOT_PID:    begin
                                    value_byte <= rx_byte; // latch VALUE
                                    state      <= GOT_VAL;
                                 end

                    //--------------------------------------------------
                    GOT_VAL:    begin
                                    if (rx_byte == END_FRAME) begin
                                        // shadow copies so we can update & test in same cycle
                                        reg [3:0] a1_written_n;
                                        reg [3:0] a2_written_n;
                                        a1_written_n = a1_written;
                                        a2_written_n = a2_written;

                                        // --------------------------------------------------
                                        // store VALUE into correct byte lane
                                        case (pid_byte)
                                            // ---- a1 bytes
                                            8'h10: begin a1_bytes[3] <= value_byte; a1_written_n[3] = 1'b1; end
                                            8'h11: begin a1_bytes[2] <= value_byte; a1_written_n[2] = 1'b1; end
                                            8'h12: begin a1_bytes[1] <= value_byte; a1_written_n[1] = 1'b1; end
                                            8'h13: begin a1_bytes[0] <= value_byte; a1_written_n[0] = 1'b1; end
                                            // ---- a2 bytes
                                            8'h20: begin a2_bytes[3] <= value_byte; a2_written_n[3] = 1'b1; end
                                            8'h21: begin a2_bytes[2] <= value_byte; a2_written_n[2] = 1'b1; end
                                            8'h22: begin a2_bytes[1] <= value_byte; a2_written_n[1] = 1'b1; end
                                            8'h23: begin a2_bytes[0] <= value_byte; a2_written_n[0] = 1'b1; end
                                            // ---- test frame (immediate ready)
                                            TEST_PID: begin
                                                a1_bytes[0] <= value_byte;
                                                a2_bytes[0] <= value_byte;
                                                set_ready   <= 1'b1;
                                                a1_written_n = 4'b0;
                                                a2_written_n = 4'b0;
                                            end
                                            default: ; // ignore unknown PID
                                        endcase

                                        // write back updated flags
                                        a1_written <= a1_written_n;
                                        a2_written <= a2_written_n;

                                        // completeness check (non-test frame)
                                        if (pid_byte != TEST_PID &&
                                            &a1_written_n && &a2_written_n) begin
                                            set_ready  <= 1'b1;
                                            a1_written <= 4'b0;
                                            a2_written <= 4'b0;
                                        end
                                    end
                                    state <= IDLE;
                                 end
                    //--------------------------------------------------
                    default:     state <= IDLE;
                endcase
            end
        end
    end

    //------------------------------------------------------------------
    // Output update & one-cycle ready pulse
    //------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            a1 <= 32'h0;  a2 <= 32'h0;
            ready <= 1'b0; test <= 1'b0;
            set_ready_ff <= 1'b0;
        end else begin
            set_ready_ff <= set_ready;              // 1-cycle register

            if (set_ready_ff) begin
                a1    <= {a1_bytes[3], a1_bytes[2], a1_bytes[1], a1_bytes[0]};
                a2    <= {a2_bytes[3], a2_bytes[2], a2_bytes[1], a2_bytes[0]};
                ready <= 1'b1;
            end else begin
                ready <= 1'b0;
            end

            test <= (pid_byte == TEST_PID);
        end
    end

endmodule

