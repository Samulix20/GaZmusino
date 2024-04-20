/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_decoder (
    input rv_instr_t instr,
    output decoded_instr_t decoded_instr,
    // Register use for dependecy detection
    output logic [1:0] use_rs
);

always_comb begin
// Default signals NOP Setup add x0, x0, 0;
    decoded_instr = create_nop_ctrl();

    use_rs[0] = 0;
    use_rs[1] = 0;

    case(instr.opcode)
        // Load upper imm
        // ALU: 0 + U_IMM
        // RD = ALU
        OPCODE_LUI: begin
            decoded_instr.t = INSTR_U_TYPE;
            decoded_instr.int_alu_i2 = ALU_IN_IMM;
            decoded_instr.register_wb = 1;
        end

        // Load upper imm+pc
        // ALU: PC + U_IMM
        // RD = ALU
        OPCODE_AUIPC: begin
            decoded_instr.t = INSTR_U_TYPE;
            decoded_instr.int_alu_i1 = ALU_IN_PC;
            decoded_instr.int_alu_i2 = ALU_IN_IMM;
            decoded_instr.register_wb = 1;
        end

        // Jump and link
        // ALU: PC + J_IMM
        // PC = ALU
        // RD = PC + 4
        OPCODE_JAL: begin
            decoded_instr.t = INSTR_J_TYPE;
            decoded_instr.branch_op = OP_J;
            decoded_instr.int_alu_i1 = ALU_IN_PC;
            decoded_instr.int_alu_i2 = ALU_IN_IMM;
            decoded_instr.register_wb = 1;
            decoded_instr.wb_result_src = WB_PC4;
        end

        // Jump and link using register
        // ALU: R1 + J_IMM
        // PC = ALU
        // RD = PC + 4
        OPCODE_JALR: begin
            decoded_instr.t = INSTR_R_TYPE;
            decoded_instr.branch_op = OP_J;
            decoded_instr.int_alu_i1 = ALU_IN_REG_1;
            decoded_instr.int_alu_i2 = ALU_IN_IMM;
            decoded_instr.register_wb = 1;
            decoded_instr.wb_result_src = WB_PC4;
        end

        // Branch instruction
        // ALU: PC + B_IMM
        // PC = ALU
        // B_UNIT: R1, R2
        OPCODE_BRANCH: begin
            decoded_instr.t = INSTR_B_TYPE;
            decoded_instr.branch_op = branch_op_t'({1'b0, instr.funct3});
            decoded_instr.int_alu_i1 = ALU_IN_PC;
            decoded_instr.int_alu_i2 = ALU_IN_IMM;
            use_rs[0] = 1;
            use_rs[1] = 1;
        end

        // Integer Immediate arithmetic
        // ALU: R1, I_IMM
        // RD = ALU
        OPCODE_INTEGER_IMM: begin
            decoded_instr.t = INSTR_I_TYPE;
            decoded_instr.int_alu_op = int_alu_op_t'({1'b0, instr.funct3});
            decoded_instr.int_alu_i1 = ALU_IN_REG_1;
            decoded_instr.int_alu_i2 = ALU_IN_IMM;
            decoded_instr.register_wb = 1;
            use_rs[0] = 1;
        end

        // Integer register arithmetic
        // ALU: R1, R2
        // RD = ALU
        OPCODE_INTEGER_REG: begin
            decoded_instr.t = INSTR_R_TYPE;
            decoded_instr.int_alu_op = int_alu_op_t'({instr.funct7[5], instr.funct3});
            decoded_instr.int_alu_i1 = ALU_IN_REG_1;
            decoded_instr.int_alu_i2 = ALU_IN_REG_2;
            decoded_instr.register_wb = 1;
            use_rs[0] = 1;
            use_rs[1] = 1;
        end

        default: begin
            // Invalid instruction detection
            decoded_instr.invalid = 1;
        end
    endcase
end


endmodule
