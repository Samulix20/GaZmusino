/* verilator lint_off UNUSEDSIGNAL */

module rv32_decoder
import rv32_types::*;
(
    input rv_instr_t instr,
    output decoded_instr_t decoded_instr,
    // Register use for dependecy detection
    output logic use_rs [3]
);

always_comb begin
    // Logic for detecting SRAI instruction
    logic is_srai = 0;

    // Default signals NOP Setup add x0, x0, 0;
    decoded_instr = create_nop_ctrl();

    use_rs[0] = 0; // rs1
    use_rs[1] = 0; // rs2
    use_rs[2] = 0; // rs3 == rd

    case(instr.opcode)
        // Load upper imm
        // ALU: 0 + U_IMM
        // RD = ALU
        OPCODE_LUI: begin
            decoded_instr.t = INSTR_U_TYPE;
            decoded_instr.int_alu_input[1] = ALU_IN_IMM;
            decoded_instr.register_wb = 1;
        end

        // Load upper imm+pc
        // ALU: PC + U_IMM
        // RD = ALU
        OPCODE_AUIPC: begin
            decoded_instr.t = INSTR_U_TYPE;
            decoded_instr.int_alu_input[0] = ALU_IN_PC;
            decoded_instr.int_alu_input[1] = ALU_IN_IMM;
            decoded_instr.register_wb = 1;
        end

        // Jump and link
        // ALU: PC + J_IMM
        // PC = ALU
        // RD = PC + 4
        OPCODE_JAL: begin
            decoded_instr.t = INSTR_J_TYPE;
            decoded_instr.branch_op = OP_J;
            decoded_instr.int_alu_input[0] = ALU_IN_PC;
            decoded_instr.int_alu_input[1] = ALU_IN_IMM;
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
            decoded_instr.int_alu_input[0] = ALU_IN_REG_1;
            decoded_instr.int_alu_input[1] = ALU_IN_IMM;
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
            decoded_instr.int_alu_input[0] = ALU_IN_PC;
            decoded_instr.int_alu_input[1] = ALU_IN_IMM;
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
            decoded_instr.t = INSTR_I_TYPE;
            decoded_instr.int_alu_op = int_alu_op_t'({is_srai, instr.funct3});
            decoded_instr.int_alu_input[0] = ALU_IN_REG_1;
            decoded_instr.int_alu_input[1] = ALU_IN_IMM;
            decoded_instr.register_wb = 1;
            use_rs[0] = 1;
        end

        // Integer register op register arithmetic
        OPCODE_INTEGER_REG: begin

            decoded_instr.t = INSTR_R_TYPE;
            decoded_instr.register_wb = 1;
            use_rs[0] = 1;
            use_rs[1] = 1;

            case (instr.funct7)
                7'b0000001: begin // Mul extension
                    decoded_instr.mul_op = mul_op_t'(instr.funct3[1:0]);
                    decoded_instr.wb_result_src = WB_MUL_UNIT;
                end
                default: begin // Base integer instructions
                    decoded_instr.int_alu_op = int_alu_op_t'({instr.funct7[5], instr.funct3});
                    decoded_instr.int_alu_input[0] = ALU_IN_REG_1;
                    decoded_instr.int_alu_input[1] = ALU_IN_REG_2;
                end
            endcase

        end

        // Store
        // ALU: R1 + S_IMM
        // MEM <- R2
        OPCODE_STORE: begin
            decoded_instr.t = INSTR_S_TYPE;
            decoded_instr.int_alu_input[0] = ALU_IN_REG_1;
            decoded_instr.int_alu_input[1] = ALU_IN_IMM;
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
            decoded_instr.int_alu_input[0] = ALU_IN_REG_1;
            decoded_instr.int_alu_input[1] = ALU_IN_IMM;
            decoded_instr.mem_op = mem_op_t'({1'b0, instr.funct3});
            decoded_instr.wb_result_src = WB_MEM_DATA;
            decoded_instr.register_wb = 1;
            use_rs[0] = 1;
        end

        OPCODE_GRNG: begin
            decoded_instr.t = INSTR_R_TYPE;

            case (instr.funct3)
                3'b000: begin // Set seed
                    decoded_instr.grng_seed = 1;
                    use_rs[0] = 1;
                end
                3'b001: begin
                    decoded_instr.wb_result_src = WB_GRNG;
                    decoded_instr.grng_enable = 1; 
                    decoded_instr.register_wb = 1;
                end
                default: begin
                    decoded_instr.invalid = 1;
                end
            endcase
        end

        default: begin
            // Invalid instruction detection
            decoded_instr.invalid = 1;
        end
    endcase

    if (instr.rd == 0) decoded_instr.register_wb = 0;
end


endmodule
