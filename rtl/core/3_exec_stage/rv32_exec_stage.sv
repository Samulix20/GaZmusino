/* verilator lint_off UNUSEDSIGNAL */

module rv32_exec_stage
import rv32_types::*;
(
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

exec_mem_buffer_t internal_data /*verilator public*/;
exec_mem_buffer_t output_internal_data;

// Operand bypass
rv32_word reg_data[3];
always_comb begin
    for(int idx = 0; idx < 3; idx = idx + 1) begin
        case (decode_exec_buff.decoded_instr.bypass_rs[idx])
            BYPASS_EXEC_BUFF: reg_data[idx] = exec_mem_buff.wb_result;
            BYPASS_MEM_BUFF: reg_data[idx] = wb_bypass;
            default: reg_data[idx] = decode_exec_buff.reg_data[idx];
        endcase
    end
end

// Immediate creation logic
rv32_word immediate;
rv32_immediate_gen immediate_gen(
    .instr_type(decode_exec_buff.decoded_instr.t),
    .instruction(decode_exec_buff.instr),
    .immediate(immediate)
);

// ALU Xbar
rv32_word alu_op[2];
always_comb begin
    for(int idx = 0; idx < 2; idx = idx + 1) begin
        case (decode_exec_buff.decoded_instr.int_alu_input[idx])
            ALU_IN_REG_1: alu_op[idx] = reg_data[0];
            ALU_IN_REG_2: alu_op[idx] = reg_data[1];
            ALU_IN_PC: alu_op[idx] = decode_exec_buff.pc;
            ALU_IN_IMM: alu_op[idx] = immediate;
            default: alu_op[idx] = 0;
        endcase
    end
end

// Int ALU
rv32_word int_alu_result;
rv32_int_alu int_alu (
    .op1(alu_op[0]), .op2(alu_op[1]),
    .opsel(decode_exec_buff.decoded_instr.int_alu_op),
    .result(int_alu_result)
);

// Branch unit
rv32_branch_unit branch_unit (
    .op1(reg_data[0]), .op2(reg_data[1]),
    .branch_op(decode_exec_buff.decoded_instr.branch_op),
    .do_branch(do_jump)
);
always_comb begin
    jump_addr = int_alu_result;
end

// Mul unit
rv32_word mul_unit_result;
rv32_mul_unit mul_unit (
    .op1(reg_data[0]), .op2(reg_data[1]),
    .opsel(decode_exec_buff.decoded_instr.mul_op),
    .result(mul_unit_result)
);

// GRNG unit
rv32_word grng_result;
clt_grng_16 grng (
    .clk(clk), .resetn(resetn), 
    .enable(decode_exec_buff.decoded_instr.grng_enable),
    .seed(0), .sample(grng_result)
);


always_comb begin
    internal_data.instr = decode_exec_buff.instr;
    internal_data.pc = decode_exec_buff.pc;
    internal_data.decoded_instr = decode_exec_buff.decoded_instr;
    internal_data.mem_addr = int_alu_result;

    // Setup data for bypass
    case(decode_exec_buff.decoded_instr.wb_result_src)
        WB_PC4: internal_data.wb_result = decode_exec_buff.pc + 4;
        WB_INT_ALU: internal_data.wb_result = int_alu_result;
        WB_STORE: internal_data.wb_result = reg_data[1];
        WB_MUL_UNIT: internal_data.wb_result = mul_unit_result;
        WB_GRNG: internal_data.wb_result = grng_result;
        default: internal_data.wb_result = 0;
    endcase
end

always_ff @(posedge clk) begin
    if (!resetn) begin
        exec_mem_buff.instr <= RV_NOP;
        exec_mem_buff.pc <= 0;
        exec_mem_buff.decoded_instr <= create_nop_ctrl();
    end
    else if (!stop) exec_mem_buff <= internal_data;
end

endmodule;
