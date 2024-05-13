/* verilator lint_off UNUSEDSIGNAL */

module rv32_mul_unit
import rv32_types::*;
(
    input rv32_word op1, op2,
    input mul_op_t opsel,
    output rv32_word result
);

logic[63:0] smul, umul;
logic[32:0] sumul_op1, sumul_op2;
logic[65:0] sumul;

always_comb begin
    smul = $signed(op1) * $signed(op2);
    umul = op1 * op2;

    // Sign extension
    sumul_op1[31:0] = op1;
    sumul_op1[32] = op1[31];
    // Unsigned extension
    sumul_op2[31:0] = op2;
    sumul_op2[32] = 0;
    // Signed x Unsigned
    sumul = $signed(sumul_op1) * $signed(sumul_op2);

    case(opsel)
        MUL_OP_MUL: result = smul[31:0];
        MUL_OP_MULH: result = smul[63:32];
        MUL_OP_MULHSU: result = sumul[63:32];
        MUL_OP_MULHU: result = umul[63:32];
    endcase
end

endmodule
