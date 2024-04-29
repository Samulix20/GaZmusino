/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv_immediates"

module rv32_exec_stage (
    // Clk, Reset signals
    input logic clk, resetn,
    // Pipeline I/O
    input decode_exec_buffer_t decode_exec_buff,
    output exec_mem_buffer_t exec_mem_buff,
    input logic stop,
    // Jump control signals
    output logic do_jump,
    output rv32_word jump_addr,
    // Bypass data
    input rv32_word wb_bypass
);

// TODO Setup as a loop
function automatic rv32_word alu_input_sel(
    input logic input_sel,
    input rv32_word imm,
    input rv32_word exec_pc,
    input rv32_word reg1,
    input rv32_word reg2,
    input decode_exec_buffer_t db
);
    int_alu_input_t opsel;
    rv32_word out;

    if (input_sel == 0) opsel = db.decoded_instr.int_alu_i1;
    else opsel = db.decoded_instr.int_alu_i2;

    case (opsel)
        ALU_IN_REG_1: out = reg1;
        ALU_IN_REG_2: out = reg2;
        ALU_IN_PC: out = exec_pc;
        ALU_IN_IMM: out = imm;
        default: out = 0;
    endcase
    return out;
endfunction

exec_mem_buffer_t internal_data /*verilator public*/;
exec_mem_buffer_t output_internal_data;

rv32_word reg1, reg2;
always_comb begin
    case (decode_exec_buff.decoded_instr.bypass_rs1)
        BYPASS_EXEC_BUFF: reg1 = exec_mem_buff.wb_result;
        BYPASS_MEM_BUFF: reg1 = wb_bypass;
        default: reg1 = decode_exec_buff.reg1;
    endcase
    case (decode_exec_buff.decoded_instr.bypass_rs2)
        BYPASS_EXEC_BUFF: reg2 = exec_mem_buff.wb_result;
        BYPASS_MEM_BUFF: reg2 = wb_bypass;
        default: reg2 = decode_exec_buff.reg2;
    endcase
end

// Immediate creation logic
rv32_word imm;
always_comb begin
    case (decode_exec_buff.decoded_instr.t)
        INSTR_I_TYPE: imm = decode_i_imm(decode_exec_buff.instr);
        INSTR_S_TYPE: imm = decode_s_imm(decode_exec_buff.instr);
        INSTR_B_TYPE: imm = decode_b_imm(decode_exec_buff.instr);
        INSTR_U_TYPE: imm = decode_u_imm(decode_exec_buff.instr);
        INSTR_J_TYPE: imm = decode_j_imm(decode_exec_buff.instr);
        default: imm = 0;
    endcase
end

rv32_word alu_op1, alu_op2;
always_comb begin
    // Alu inputs setup
    alu_op1 = alu_input_sel(0, imm, decode_exec_buff.pc, reg1, reg2, decode_exec_buff);
    alu_op2 = alu_input_sel(1, imm, decode_exec_buff.pc, reg1, reg2, decode_exec_buff);
end

// Int ALU
rv32_word int_alu_result;
rv32_int_alu int_alu (
    .op1(alu_op1), .op2(alu_op2),
    .opsel(decode_exec_buff.decoded_instr.int_alu_op),
    .result(int_alu_result)
);

// Branch unit
rv32_branch_unit branch_unit (
    .op1(reg1), .op2(reg2),
    .branch_op(decode_exec_buff.decoded_instr.branch_op),
    .do_branch(do_jump)
);
always_comb begin
    jump_addr = int_alu_result;
end

always_comb begin
    internal_data.instr = decode_exec_buff.instr;
    internal_data.pc = decode_exec_buff.pc;
    internal_data.decoded_instr = decode_exec_buff.decoded_instr;
    internal_data.mem_addr = int_alu_result;

    // Setup data for bypass
    case(decode_exec_buff.decoded_instr.wb_result_src)
        WB_PC4: internal_data.wb_result = decode_exec_buff.pc + 4;
        WB_INT_ALU: internal_data.wb_result = int_alu_result;
        WB_STORE: internal_data.wb_result = reg2;
        default: internal_data.wb_result = 0;
    endcase
end

always_ff @(posedge clk) begin
    if (!resetn) begin
        exec_mem_buff.instr <= `RV_NOP;
        exec_mem_buff.pc <= 0;
        exec_mem_buff.decoded_instr <= create_nop_ctrl();
    end
    else if (!stop) exec_mem_buff <= internal_data;
end

endmodule;
