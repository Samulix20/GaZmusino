/* verilator lint_off UNUSEDSIGNAL */

/*
 RISCV 5-stage in order core
 Fetch | Decode | Execute | Memory | Writeback
*/

module rv32_core
import rv32_types::*;
(
    // Clk, Reset signals
    input logic clk, resetn,
    // Instructions memory port
    output memory_request_t instr_request,
    input logic instr_request_done,
    input rv_instr_t instr,
    // Data memory port
    output memory_request_t data_request,
    input logic data_request_done,
    input rv32_word data
);

// Stage buffers
fetch_decode_buffer_t fetch_decode_buff /*verilator public*/;
decode_exec_buffer_t decode_exec_buff /*verilator public*/;
exec_mem_buffer_t exec_mem_buff /*verilator public*/;
mem_wb_buffer_t mem_wb_buff /*verilator public*/;

// Bypass signals
rv32_word wb_bypass;

// PC/Jump logic
logic exec_jump /*verilator public*/;
logic jump_set_nop;
rv32_word exec_jump_addr, jump_nop_pc;
rv32_word pc, next_pc /*verilator public*/;

always_comb begin
    jump_set_nop = 0;
    jump_nop_pc = decode_exec_buff.pc;

    // Default pc increase
    next_pc = pc + 4;

    // Jump instruction
    if(exec_jump) begin
        next_pc = exec_jump_addr;
        jump_set_nop = 1;
    end

    // A instruction is stalling
    else if (dec_stall | mem_stall) next_pc = pc;
end

always_ff @(posedge clk) begin
    if (!resetn) pc <= 0;
    else pc <= next_pc;
end

// Register file
rv_reg_id_t [CORE_RF_NUM_READ - 1:0] rs;
rv32_word [CORE_RF_NUM_READ - 1:0] reg_data;
always_comb begin
    rv_r4_instr_t r4_instr = instr; // R4-Encoding
    rs[0] = r4_instr.rs1;
    rs[1] = r4_instr.rs2;
    rs[2] = r4_instr.rs3;
end

register_write_request_t rf_write_request /*verilator public*/;
rv32_register_file #(.NUM_READ_PORTS(CORE_RF_NUM_READ)) rf(
    .clk(clk),
    // Decode (read) interface
    .rs(rs), .o(reg_data),
    // Writeback (write) interface
    .write_request(rf_write_request)
);

// CSR
rv32_word csr_read_data;
rv_csr_id_t csr_read_id;
csr_write_request_t csr_write_request;
logic instr_retired = 0;
always_comb begin 
    csr_read_id = instr[31:20];
end
rv32_csr csr_file(
    .clk(clk), .resetn(resetn),
    .read_id(csr_read_id), .read_value(csr_read_data),
    .write_request(csr_write_request),
    .instr_retired(instr_retired),
    .dec_stall(dec_stall),
    .jump_taken(exec_jump)
);

// FETCH STAGE
logic fetch_stall /*verilator public*/;
rv32_fetch_stage fetch_stage(
    .clk(clk), .resetn(resetn),
    // Pipeline I/O
    .pc(pc),
    .fetch_decode_buff(fetch_decode_buff),
    // Control
    .stall(fetch_stall),
    .stop(dec_stall | mem_stall),
    // Jump signals
    .set_nop(jump_set_nop),
    .set_nop_pc(jump_nop_pc),
    // INSTR MEM I/O
    .instr_request(instr_request),
    .request_done(instr_request_done)
);

// DECODE STAGE
logic dec_stall /*verilator public*/;
rv32_decode_stage decode_stage(
    .clk(clk), .resetn(resetn),
    // Pipeline I/O
    .fetch_decode_buff(fetch_decode_buff),
    .instr(instr),
    .decode_exec_buff(decode_exec_buff),
    // Control
    .stall(dec_stall),
    .stop(mem_stall),
    // Jump signals
    .set_nop(jump_set_nop),
    .set_nop_pc(jump_nop_pc),
    // Register file read
    .reg_data(reg_data),
    // CSR file read
    .csr_data(csr_read_data),
    // Hazzard detection
    .exec_mem_buff(exec_mem_buff)
);

// EXECUTION STAGE
rv32_exec_stage exec_stage(
    .clk(clk), .resetn(resetn),
    // Pipeline I/O
    .decode_exec_buff(decode_exec_buff),
    .exec_mem_buff(exec_mem_buff),
    // Control
    .stop(mem_stall),
    // Jump signals
    .do_jump(exec_jump),
    .jump_addr(exec_jump_addr),
    // Bypass
    .wb_bypass(rf_write_request.data)
);

// MEMORY STAGE
logic mem_stall /*verilator public*/;
rv32_mem_stage mem_stage(
    .clk(clk), .resetn(resetn),
    // Pipeline I/O
    .exec_mem_buff(exec_mem_buff),
    .mem_wb_buff(mem_wb_buff),
    // Control
    .stall(mem_stall),
    // Data Memory I/O
    .data_request(data_request),
    .request_done(data_request_done),
    // CSR File O
    .csr_write_request(csr_write_request),
    .instr_retired(instr_retired)
);

// WRITEBACK STAGE
rv32_wb_stage wb_stage(
    .mem_wb_buff(mem_wb_buff),
    // Memory I
    .mem_data(data),
    // Register File O
    .rf_write_request(rf_write_request)
);

endmodule
