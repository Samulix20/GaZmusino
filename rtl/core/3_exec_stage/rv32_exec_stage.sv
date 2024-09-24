/* verilator lint_off UNUSEDSIGNAL */

/* 
 CPU 3 execution stage
 - Bypass
 - Immediate generation
 - Integer ALU
 - Integer MUL
 - Branch
*/

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

// Operand bypass
rv32_word reg_data[3] /*verilator public*/;
always_comb begin
    for(int idx = 0; idx < 3; idx = idx + 1) begin
        case (decode_exec_buff.control.bypass_rs[idx])
            BYPASS_EXEC_BUFF: reg_data[idx] = exec_mem_buff.data_result[0];
            BYPASS_MEM_BUFF: reg_data[idx] = wb_bypass;
            default: reg_data[idx] = decode_exec_buff.reg_data[idx];
        endcase
    end
end

// Immediate creation logic
rv32_word immediate;
rv32_immediate_gen immediate_gen(
    .instr_type(decode_exec_buff.control.t),
    .instruction(decode_exec_buff.instr),
    .immediate(immediate)
);

// Zicsr functional unit
zicsr_op_t zicsr_unit_op;
rv32_word zicsr_operand_data, zicsr_reg_result, zicsr_csr_result;
// Operand selection
always_comb begin
    zicsr_unit_op = zicsr_op_t'(decode_exec_buff.instr.funct3[1:0]);
    // Register
    if (decode_exec_buff.instr.funct3[2] == 0) zicsr_operand_data = reg_data[0];
    // Special Immediate
    else begin
        zicsr_operand_data[4:0] = decode_exec_buff.instr.rs1;
        zicsr_operand_data[31:5] = 0;
    end
end
rv32_zicsr_unit zicsr_unit (
    .csr(reg_data[2]), .operand(zicsr_operand_data),
    .opsel(zicsr_unit_op),
    .reg_result(zicsr_reg_result), .csr_result(zicsr_csr_result)
);

// Int ALU and Xbar
rv32_word alu_op[2];
always_comb begin
    for(int idx = 0; idx < 2; idx = idx + 1) begin
        case (decode_exec_buff.control.int_alu_instr.xbar[idx])
            ALU_IN_REG_1: alu_op[idx] = reg_data[0];
            ALU_IN_REG_2: alu_op[idx] = reg_data[1];
            ALU_IN_PC: alu_op[idx] = decode_exec_buff.pc;
            ALU_IN_IMM: alu_op[idx] = immediate;
            default: alu_op[idx] = 0;
        endcase
    end
end
rv32_word int_alu_result;
rv32_int_alu int_alu (
    .op1(alu_op[0]), .op2(alu_op[1]),
    .opsel(decode_exec_buff.control.int_alu_instr.op),
    .result(int_alu_result)
);

// Branch unit
rv32_branch_unit branch_unit (
    .op1(reg_data[0]), .op2(reg_data[1]),
    .branch_op(decode_exec_buff.control.branch_op),
    .do_branch(do_jump)
);
always_comb begin
    jump_addr = int_alu_result;
end

// Mul unit
mul_op_t mul_unit_op;
rv32_word mul_unit_result;
always_comb begin 
    mul_unit_op = mul_op_t'(decode_exec_buff.instr.funct3[1:0]);
end
rv32_mul_unit mul_unit (
    .op1(reg_data[0]), .op2(reg_data[1]),
    .opsel(mul_unit_op),
    .result(mul_unit_result)
);

// Custom extension functional units
// GRNG unit
rv32_word grng_result;
clt_grng_16 grng (
    .clk(clk), .resetn(resetn), 
    .ctrl(decode_exec_buff.control.grng_ctrl),
    .seed(reg_data[0]),
    .sample(grng_result)
);

// Custom signal for simulation of custom isntructions
logic tb_exec /*verilator public*/;

always_comb begin
    internal_data.instr = decode_exec_buff.instr;
    internal_data.pc = decode_exec_buff.pc;


    if (tb_exec == 0) begin

        internal_data.control = decode_exec_buff.control;
        internal_data.data_result[1] = int_alu_result;

        // Setup data for bypass
        case(decode_exec_buff.control.wb_result_src)
            WB_PC4: internal_data.data_result[0] = decode_exec_buff.pc + 4;
            WB_INT_ALU: internal_data.data_result[0] = int_alu_result;
            WB_STORE: internal_data.data_result[0] = reg_data[1];
            WB_MUL_UNIT: internal_data.data_result[0] = mul_unit_result;
            WB_CSR: begin 
                internal_data.data_result[0] = zicsr_reg_result;
                internal_data.data_result[1] = zicsr_csr_result;
            end

            // Custom functional unit outputs
            WB_GRNG: internal_data.data_result[0] = grng_result;

            default: internal_data.data_result[0] = 0;
        endcase

    end


end

always_ff @(posedge clk) begin
    if (!resetn) begin
        exec_mem_buff.instr <= RV_NOP;
        exec_mem_buff.pc <= 0;
        exec_mem_buff.control <= create_nop_ctrl();
    end
    else if (!stop) exec_mem_buff <= internal_data;
end

endmodule;
