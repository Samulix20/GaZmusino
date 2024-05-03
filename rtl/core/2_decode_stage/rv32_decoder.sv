/* verilator lint_off UNUSEDSIGNAL */

module rv32_decoder
import rv32_types::*;
(
    input rv_instr_t instr,
    output decoded_instr_t decoded_instr,
    // Register use for dependecy detection
    output logic [1:0] use_rs
);

always_comb begin
    // Logic for detecting SRAI instruction
    logic is_srai = 0;

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
            decoded_instr.t = INSTR_I_TYPE;
            decoded_instr.branch_op = OP_J;
            decoded_instr.int_alu_i1 = ALU_IN_REG_1;
            decoded_instr.int_alu_i2 = ALU_IN_IMM;
            decoded_instr.register_wb = 1;
            decoded_instr.wb_result_src = WB_PC4;
            use_rs[0] = 1;
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
            // SRAI instr is the only that sets alu_op to 1xxx
            if (instr.funct3 == 3'b101 && instr.funct7[5]) is_srai = 1;
            decoded_instr.t = INSTR_I_TYPE;
            decoded_instr.int_alu_op = int_alu_op_t'({is_srai, instr.funct3});
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

        // Store
        // ALU: R1 + S_IMM
        // MEM <- R2
        OPCODE_STORE: begin
            decoded_instr.t = INSTR_S_TYPE;
            decoded_instr.int_alu_i1 = ALU_IN_REG_1;
            decoded_instr.int_alu_i2 = ALU_IN_IMM;
            decoded_instr.mem_op = mem_op_t'({1'b1, instr.funct3});
            decoded_instr.wb_result_src = WB_STORE;
            use_rs[0] = 1;
            use_rs[1] = 1;
        end

        // Load
        // ALU: R1 + I_IMM
        // RD = MEM
        OPCODE_LOAD: begin
            decoded_instr.t = INSTR_I_TYPE;
            decoded_instr.int_alu_i1 = ALU_IN_REG_1;
            decoded_instr.int_alu_i2 = ALU_IN_IMM;
            decoded_instr.mem_op = mem_op_t'({1'b0, instr.funct3});
            decoded_instr.wb_result_src = WB_MEM_DATA;
            decoded_instr.register_wb = 1;
            use_rs[0] = 1;
        end

        default: begin
            // Invalid instruction detection
            decoded_instr.invalid = 1;
        end
    endcase

    // Todo make register use check with automatic with code

    if (instr.rd == 0) decoded_instr.register_wb = 0;
end


endmodule
