// FXMADD UNIT

module rv32_fxmadd_unit
import rv32_types::*;
(
    // Operands
    input  rv32_word mul_op_1, mul_op_2, add_op,
    // Shift scale
    input logic[2:0] low_bits_selected_scale,
    input logic[1:0] high_bit_selected_scale,
    // Output
    output rv32_word result 
);

logic[31:0] res_mul, res_mul_shifted;
logic[4:0] shift_value = {high_bit_selected_scale, low_bits_selected_scale};

always_comb begin
    res_mul = $signed(mul_op_1) * $signed(mul_op_2);
    res_mul_shifted = $signed(res_mul) >>> shift_value;
    result = $signed(res_mul_shifted) + $signed(add_op);
end

endmodule
