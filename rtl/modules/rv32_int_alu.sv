`include "rtl/rv32_types"

module rv32_int_alu (
    input rv32_word op1, op2,
    int_alu_op_t opsel,
    output rv32_word result
);

// Simple ALU design not reusing adder for sub sum cmp
always_comb begin
    case (opsel)
        ALU_OP_ADD: begin
            result = op1 + op2;
        end
        ALU_OP_SLL: begin
            result = op1 << op2;
        end
        ALU_OP_SLT: begin
            result = '{0: $signed(op1) < $signed(op2), default: 0};
        end
        ALU_OP_SLTU: begin
            result = '{0: op1 < op2, default: 0};
        end
        ALU_OP_XOR: begin
            result = op1 ^ op2;
        end
        ALU_OP_SRL: begin
            result = op1 >> op2;
        end
        ALU_OP_OR: begin
            result = op1 | op2;
        end
        ALU_OP_AND: begin
            result = op1 & op2;
        end
        ALU_OP_SRA: begin
            result = $signed(op1) >>> op2;
        end
        ALU_OP_SUB: begin
            result = op1 - op2;
        end
        default: result = 0;
    endcase
end

endmodule
