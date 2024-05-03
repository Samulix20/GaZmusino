/* verilator lint_off UNUSEDSIGNAL */

module rv32_core
import rv32_types::*;
(
    // Clk, Reset signals
    input logic clk, resetn,
    // Instructions memory port
    output memory_request_t instr_request,
    input logic instr_request_done,
    input rv32_word instr,
    // Data memory port
    output memory_request_t data_request,
    input logic data_request_done,
    input rv32_word data
);

rv32_word pc;
fetch_decode_buffer_t fetch_decode_buff /*verilator public*/;
decode_exec_buffer_t decode_exec_buff /*verilator public*/;
exec_mem_buffer_t exec_mem_buff /*verilator public*/;
mem_wb_buffer_t mem_wb_buff /*verilator public*/;
rv32_word wb_bypass;

// PC/Jump logic
logic exec_jump /*verilator public*/;
logic jump_set_nop;
rv32_word exec_jump_addr, jump_nop_pc;


rv32_word next_pc /*verilator public*/;
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
rv_reg_id_t dec_rs1, dec_rs2, wb_rd;
rv32_word dec_reg1, dec_reg2;
rv32_word wb_data /*verilator public*/;
logic wb_we;
rv32_register_file rf(
    .clk(clk), .resetn(resetn),
    // Decode interface
    .r1(dec_rs1), .o1(dec_reg1),
    .r2(dec_rs2), .o2(dec_reg2),
    // Writeback interface
    .write(wb_we), .d(wb_data), .rw(wb_rd)
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
    // Register file read I/O
    .rs1(dec_rs1), .rs2(dec_rs2),
    .reg1(dec_reg1), .reg2(dec_reg2),
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
    .wb_bypass(wb_data)
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
    .request_done(data_request_done)
);

// WRITEBACK STAGE
rv32_wb_stage wb_stage(
    .mem_wb_buff(mem_wb_buff),
    // Memory I
    .mem_data(data),
    // Register File O
    .reg_write(wb_we), .rd(wb_rd), .wb_data(wb_data)
);

endmodule
