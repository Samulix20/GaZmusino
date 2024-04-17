`ifndef RV_INT_ALU
`define RV_INT_ALU

`include "rtl/rv32_types"

// SLT set less than
// SLL shift left logical
// SRL shift right logical
// SRA shift right arithmetic

typedef enum logic [3:0] {
    ALU_OP_ADD  = 4'b0000,
    ALU_OP_SLL  = 4'b0001,
    ALU_OP_SLT  = 4'b0010,
    ALU_OP_SLTU = 4'b0011,
    ALU_OP_XOR  = 4'b0100,
    ALU_OP_SRL  = 4'b0101,
    ALU_OP_OR   = 4'b0110,
    ALU_OP_AND  = 4'b0111,
    ALU_OP_SRA  = 4'b1000,
    ALU_OP_SUB  = 4'b1001
} alu_opsel_t /*verilator public*/;

module rv32_int_alu (
    input rv32_word op1, op2,
    alu_opsel_t opsel,
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

`endif
