// FXMADD UNIT

module rv32_fxmadd_unit
import rv32_types::*;
(
    // Inputs
    // Clk signal
    input logic clk,
    // Operands
    input  rv32_word mul_op_1, mul_op_2, add_op,
    input  logic[2:0] selected_scale,
    // Control bit to overwrite shift scales
    input  logic  write_enable,
    input  logic[4:0] new_scale,
    // Output
    output rv32_word result 
);

logic[31:0] res_mul, res_mul_shifted;
logic[4:0] shift_scales [7:0];

// Initialize the shift scales array
task initialize_scales();
    shift_scales[0] = 5'd0;
    shift_scales[1] = 5'd1;
    shift_scales[2] = 5'd2;
    shift_scales[3] = 5'd3;
    shift_scales[4] = 5'd4;
    shift_scales[5] = 5'd5;
    shift_scales[6] = 5'd6;
    shift_scales[7] = 5'd7;
endtask

initial begin
    initialize_scales();
end


always_ff @(posedge clk) begin
    if(write_enable) begin
        shift_scales[selected_scale] <= new_scale;
    end
end


always_comb begin
    res_mul = $signed(mul_op_1) * $signed(mul_op_2);
    res_mul_shifted = $signed(res_mul) >>> shift_scales[selected_scale];
    result = $signed(res_mul_shifted) + $signed(add_op);
end

endmodule
