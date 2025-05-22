// ====================================
// File: control_law.v
// Author: jaimebw
// Created: 2025-04-06 13:54:08
// ====================================
module LandauControlLaw#(
`ifdef SIM_MODE
    parameter signed [31:0] K1 = 32'sd65536,  // 1.0 in Q16.16
    parameter signed [31:0] K2 = 32'sd65536   // 1.0 in Q16.16
`else
    parameter signed [31:0] K1 = -32'sd13107, // -0.2 in Q16.16
    parameter signed [31:0] K2 = -32'sd26214  // -0.4 in Q16.16
`endif
)(
    input wire signed [31:0] a1,
    input wire signed [31:0] a2,
    input wire test,
    output reg signed [31:0] b
);

    wire signed [63:0] mult1_wide = a1 * K1;
    wire signed [63:0] mult2_wide = a2 * K2;
    wire signed [63:0] sum_wide   = mult1_wide + mult2_wide;
    wire signed [31:0] sum_result = sum_wide[47:16];

    always @(*) begin
        if (test) begin
            b = a1 + 32'sh00010000; // Add 1.0 in Q16.16
        end else begin
            b = sum_result;
        end
    end

endmodule

