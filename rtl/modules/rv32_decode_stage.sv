/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_decode_stage (
    // Clk, Reset signals
    input logic clk, resetn,
    // Pipeline I/O
    input logic set_nop,
    input rv32_word set_nop_pc,
    input fetch_buffer_data_t instr_data,
    output decoded_buffer_data_t decode_data,
    output logic stall,
    // Register file read I/O
    output rv_reg_id_t rs1, rs2,
    input rv32_word reg1, reg2
);

decoded_buffer_data_t internal_data /*verilator public*/;

// Decode logic
always_comb begin
    // Forward signals
    internal_data.pc = instr_data.pc;
    internal_data.instr = instr_data.instr;

    // Register file data
    rs1 = instr_data.instr.rs1;
    rs2 = instr_data.instr.rs2;
    internal_data.reg1 = reg1;
    internal_data.reg2 = reg2;

    // Default signals NOP Setup add x0, x0, 0;
    internal_data.decoded_instr = create_nop_ctrl();

    case(instr_data.instr.opcode)
        // Load upper imm
        // ALU: 0 + U_IMM
        // RD = ALU
        OPCODE_LUI: begin
            internal_data.decoded_instr.t = INSTR_U_TYPE;
            internal_data.decoded_instr.int_alu_i2 = ALU_IN_IMM;
            internal_data.decoded_instr.register_wb = 1;
        end

        // Load upper imm+pc
        // ALU: PC + U_IMM
        // RD = ALU
        OPCODE_AUIPC: begin
            internal_data.decoded_instr.t = INSTR_U_TYPE;
            internal_data.decoded_instr.int_alu_i1 = ALU_IN_PC;
            internal_data.decoded_instr.int_alu_i2 = ALU_IN_IMM;
            internal_data.decoded_instr.register_wb = 1;
        end

        // Jump and link
        // ALU: PC + J_IMM
        // PC = ALU
        // RD = PC + 4
        OPCODE_JAL: begin
            internal_data.decoded_instr.t = INSTR_J_TYPE;
            internal_data.decoded_instr.branch_op = OP_J;
            internal_data.decoded_instr.int_alu_i1 = ALU_IN_PC;
            internal_data.decoded_instr.int_alu_i2 = ALU_IN_IMM;
            internal_data.decoded_instr.register_wb = 1;
            internal_data.decoded_instr.wb_result_src = WB_PC4;
        end

        // Jump and link using register
        // ALU: R1 + J_IMM
        // PC = ALU
        // RD = PC + 4
        OPCODE_JALR: begin
            internal_data.decoded_instr.t = INSTR_R_TYPE;
            internal_data.decoded_instr.branch_op = OP_J;
            internal_data.decoded_instr.int_alu_i1 = ALU_IN_REG_1;
            internal_data.decoded_instr.int_alu_i2 = ALU_IN_IMM;
            internal_data.decoded_instr.register_wb = 1;
            internal_data.decoded_instr.wb_result_src = WB_PC4;
        end

        // Branch instruction
        // ALU: PC + B_IMM
        // PC = ALU
        // B_UNIT: R1, R2
        OPCODE_BRANCH: begin
            internal_data.decoded_instr.t = INSTR_B_TYPE;
            internal_data.decoded_instr.branch_op = branch_op_t'({1'b0, instr_data.instr.funct3});
            internal_data.decoded_instr.int_alu_i1 = ALU_IN_PC;
            internal_data.decoded_instr.int_alu_i2 = ALU_IN_IMM;
        end

        // Integer Immediate arithmetic
        // ALU: R1, I_IMM
        // RD = ALU
        OPCODE_INTEGER_IMM: begin
            internal_data.decoded_instr.t = INSTR_I_TYPE;
            internal_data.decoded_instr.int_alu_op = int_alu_op_t'({1'b0, instr_data.instr.funct3});
            internal_data.decoded_instr.int_alu_i1 = ALU_IN_REG_1;
            internal_data.decoded_instr.int_alu_i2 = ALU_IN_IMM;
            internal_data.decoded_instr.register_wb = 1;
        end

        // Integer register arithmetic
        // ALU: R1, R2
        // RD = ALU
        OPCODE_INTEGER_REG: begin
            internal_data.decoded_instr.t = INSTR_R_TYPE;
            internal_data.decoded_instr.int_alu_op =
                int_alu_op_t'({instr_data.instr.funct7[5], instr_data.instr.funct3});
            internal_data.decoded_instr.int_alu_i1 = ALU_IN_REG_1;
            internal_data.decoded_instr.int_alu_i2 = ALU_IN_REG_2;
            internal_data.decoded_instr.register_wb = 1;
        end

        default: begin
            // Invalid instruction detection
            internal_data.decoded_instr.invalid = 1;
        end
    endcase

    if(set_nop | !resetn) begin
        internal_data.instr = `RV_NOP;
        internal_data.pc = set_nop_pc;
        internal_data.decoded_instr = create_nop_ctrl();
    end

    // TODO make hazzard detection
    stall = 0;
end

always_ff @(posedge clk) begin
    decode_data <= internal_data;
end

endmodule
