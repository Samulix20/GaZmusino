/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv_immediates"

module rv32_exec_stage (
    // Clk, Reset signals
    input logic clk, resetn,
    // Pipeline I/O
    input decoded_buffer_data_t decoded_data,
    output exec_buffer_data_t exec_data,
    // Jump control signals
    output logic do_jump,
    output rv32_word jump_addr,
    // Bypass data
    input mem_buffer_data_t mem_buff
);

function automatic rv32_word alu_input_sel(
    input logic input_sel,
    input rv32_word imm,
    input rv32_word exec_pc,
    input rv32_word reg1,
    input rv32_word reg2,
    input decoded_buffer_data_t db
);
    int_alu_input_t opsel;
    rv32_word out;

    if (input_sel) begin
        opsel = db.decoded_instr.int_alu_i1;
    end else begin
        opsel = db.decoded_instr.int_alu_i2;
    end

    case (opsel)
        ALU_IN_REG_1: out = reg1;
        ALU_IN_REG_2: out = reg2;
        ALU_IN_PC: out = exec_pc;
        ALU_IN_IMM: out = imm;
        default: out = 0;
    endcase
    return out;
endfunction

exec_buffer_data_t internal_data /*verilator public*/;

rv32_word reg1, reg2;
always_comb begin
    case (decoded_data.decoded_instr.bypass_rs1)
        BYPASS_EXEC_BUFF: reg1 = exec_data.wb_result;
        BYPASS_MEM_BUFF: reg1 = mem_buff.wb_result;
        default: reg1 = decoded_data.reg1;
    endcase

    case (decoded_data.decoded_instr.bypass_rs2)
        BYPASS_EXEC_BUFF: reg2 = exec_data.wb_result;
        BYPASS_MEM_BUFF: reg2 = mem_buff.wb_result;
        default: reg2 = decoded_data.reg2;
    endcase
end

// Immediate creation logic
rv32_word imm;
always_comb begin
    case (decoded_data.decoded_instr.t)
        INSTR_I_TYPE: imm = decode_i_imm(decoded_data.instr);
        INSTR_S_TYPE: imm = decode_s_imm(decoded_data.instr);
        INSTR_B_TYPE: imm = decode_b_imm(decoded_data.instr);
        INSTR_U_TYPE: imm = decode_u_imm(decoded_data.instr);
        INSTR_J_TYPE: imm = decode_j_imm(decoded_data.instr);
        default: imm = 0;
    endcase
end

rv32_word alu_op1, alu_op2;
always_comb begin
    // Alu inputs setup
    alu_op1 = alu_input_sel(0, imm, decoded_data.pc, reg1, reg2, decoded_data);
    alu_op2 = alu_input_sel(1, imm, decoded_data.pc, reg1, reg2, decoded_data);
end

// Int ALU
rv32_word int_alu_result;
rv32_int_alu int_alu (
    .op1(alu_op1), .op2(alu_op2),
    .opsel(decoded_data.decoded_instr.int_alu_op),
    .result(int_alu_result)
);

// Branch unit
rv32_branch_unit branch_unit (
    .op1(reg1), .op2(reg2),
    .branch_op(decoded_data.decoded_instr.branch_op),
    .do_branch(do_jump)
);
always_comb begin
    jump_addr = int_alu_result;
end

always_comb begin
    internal_data.instr = decoded_data.instr;
    internal_data.pc = decoded_data.pc;
    internal_data.decoded_instr = decoded_data.decoded_instr;
    internal_data.mem_addr = int_alu_result;

    // Setup data for bypass
    case(decoded_data.decoded_instr.wb_result_src)
        WB_PC4: internal_data.wb_result = decoded_data.pc + 4;
        WB_INT_ALU: internal_data.wb_result = int_alu_result;
        default internal_data.wb_result = 0;
    endcase

    if(!resetn) begin
        internal_data.instr = `RV_NOP;
        internal_data.pc = 0;
        internal_data.decoded_instr = create_nop_ctrl();
    end
end

always_ff @(posedge clk) begin
    exec_data <= internal_data;
end

endmodule;
