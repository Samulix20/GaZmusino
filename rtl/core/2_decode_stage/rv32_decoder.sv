/* verilator lint_off UNUSEDSIGNAL */

/* 
 RISCV Instruction decoder
 - RV32I
 - C compression detection (not decoding yet)
 - Zicsr extension
*/

/*
 Custom extensions
 - GNRG
*/

module rv32_decoder
import rv32_types::*;
(
    input rv_instr_t instr,
    output rv_control_t control,
    // Register use for dependecy detection
    output logic use_rs [CORE_RF_NUM_READ]
);

always_comb begin
    // Logic for detecting SRAI instruction
    logic is_srai = 0;

    // Default signals NOP Setup add x0, x0, 0;
    control = create_nop_ctrl();

    for (int idx = 0; idx < CORE_RF_NUM_READ; idx = idx + 1) begin
        use_rs[idx] = 0; // rs1, rs2, rs3, rd
    end

    case(instr.opcode)
        // Load upper imm
        // ALU: 0 + U_IMM
        // RD = ALU
        OPCODE_LUI: begin
            control.t = INSTR_U_TYPE;
            control.int_alu_instr.xbar[1] = ALU_IN_IMM;
            control.register_wb = 1;
        end

        // Load upper imm+pc
        // ALU: PC + U_IMM
        // RD = ALU
        OPCODE_AUIPC: begin
            control.t = INSTR_U_TYPE;
            control.int_alu_instr.xbar[0] = ALU_IN_PC;
            control.int_alu_instr.xbar[1] = ALU_IN_IMM;
            control.register_wb = 1;
        end

        // Jump and link
        // ALU: PC + J_IMM
        // PC = ALU
        // RD = PC + 4
        OPCODE_JAL: begin
            control.t = INSTR_J_TYPE;
            control.branch_op = OP_J;
            control.int_alu_instr.xbar[0] = ALU_IN_PC;
            control.int_alu_instr.xbar[1] = ALU_IN_IMM;
            control.register_wb = 1;
            control.wb_result_src = WB_PC4;
        end

        // Jump and link using register
        // ALU: R1 + J_IMM
        // PC = ALU
        // RD = PC + 4
        OPCODE_JALR: begin
            control.t = INSTR_I_TYPE;
            control.branch_op = OP_J;
            control.int_alu_instr.xbar[0] = ALU_IN_REG_1;
            control.int_alu_instr.xbar[1] = ALU_IN_IMM;
            control.register_wb = 1;
            control.wb_result_src = WB_PC4;
            use_rs[0] = 1;
        end

        // Branch instruction
        // ALU: PC + B_IMM
        // PC = ALU
        // B_UNIT: R1, R2
        OPCODE_BRANCH: begin
            control.t = INSTR_B_TYPE;
            control.branch_op = branch_op_t'({1'b0, instr.funct3});
            control.int_alu_instr.xbar[0] = ALU_IN_PC;
            control.int_alu_instr.xbar[1] = ALU_IN_IMM;
            use_rs[0] = 1;
            use_rs[1] = 1;
        end

        // Integer Immediate arithmetic
        // ALU: R1, I_IMM
        // RD = ALU
        OPCODE_INTEGER_IMM: begin
            // SRAI instr is the only that sets alu_op to 1xxx
            if (instr.funct3 == 3'b101 && instr.funct7[5]) is_srai = 1;
            else is_srai = 0;
            control.t = INSTR_I_TYPE;
            control.int_alu_instr.op = int_alu_op_t'({is_srai, instr.funct3});
            control.int_alu_instr.xbar[0] = ALU_IN_REG_1;
            control.int_alu_instr.xbar[1] = ALU_IN_IMM;
            control.register_wb = 1;
            use_rs[0] = 1;
        end

        // Integer register op register arithmetic
        OPCODE_INTEGER_REG: begin

            control.t = INSTR_R_TYPE;
            control.register_wb = 1;
            use_rs[0] = 1;
            use_rs[1] = 1;

            case (instr.funct7)
                7'b0000001: begin // Mul extension
                    control.wb_result_src = WB_MUL_UNIT;
                end
                default: begin // Base integer instructions
                    control.int_alu_instr.op = int_alu_op_t'({instr.funct7[5], instr.funct3});
                    control.int_alu_instr.xbar[0] = ALU_IN_REG_1;
                    control.int_alu_instr.xbar[1] = ALU_IN_REG_2;
                end
            endcase

        end

        // Store
        // ALU: R1 + S_IMM
        // MEM <- R2
        OPCODE_STORE: begin
            control.t = INSTR_S_TYPE;
            control.int_alu_instr.xbar[0] = ALU_IN_REG_1;
            control.int_alu_instr.xbar[1] = ALU_IN_IMM;
            control.mem_op = mem_op_t'({1'b1, instr.funct3});
            control.wb_result_src = WB_STORE;
            use_rs[0] = 1;
            use_rs[1] = 1;
        end

        // Load
        // ALU: R1 + I_IMM
        // RD = MEM
        OPCODE_LOAD: begin
            control.t = INSTR_I_TYPE;
            control.int_alu_instr.xbar[0] = ALU_IN_REG_1;
            control.int_alu_instr.xbar[1] = ALU_IN_IMM;
            control.mem_op = mem_op_t'({1'b0, instr.funct3});
            control.wb_result_src = WB_MEM_DATA;
            control.register_wb = 1;
            use_rs[0] = 1;
        end

        // Zicsr
        // RD = CSR
        OPCODE_ZICSR: begin
            control.register_wb = 1;
            control.csr_wb = 1;
            control.wb_result_src = WB_CSR;
            use_rs[0] = 1;
        end

        OPCODE_CUSTOM_0: begin

            control.invalid = 1;

            /*
            // GRNG Custom extension
            // RD = GRNG
            // GRNG <- R1
            control.t = INSTR_R_TYPE;

            case (instr.funct3)
                3'b000: begin // Set seed
                    control.grng_ctrl.set_seed = 1;
                    use_rs[0] = 1;
                end
                3'b001: begin
                    control.wb_result_src = WB_GRNG;
                    control.grng_ctrl.enable = 1; 
                    control.register_wb = 1;
                end
                default: begin
                    control.invalid = 1;
                end
            endcase
            */

        end

        OPCODE_CUSTOM_1: begin
            control.invalid = 1;
        end

        default: begin
            // Invalid instruction detection
            control.invalid = 1;
        end
    endcase

    if (instr.rd == 0) control.register_wb = 0;
end


endmodule
