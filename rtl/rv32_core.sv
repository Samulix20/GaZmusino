/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_core (
    // Clk, Reset signals
    input logic clk, resetn,
    // Instructions memory port
    output memory_request_t instr_request,
    input memory_response_t instr_response,
    // Data memory port
    output memory_request_t data_request,
    input memory_response_t data_response
);

rv32_word pc;
fetch_decode_buffer_t fetch_decode_buff /*verilator public*/;
decode_exec_buffer_t decode_exec_buff /*verilator public*/;
exec_mem_buffer_t exec_mem_buff /*verilator public*/;
mem_wb_buffer_t mem_wb_buff /*verilator public*/;

// PC/Jump logic
logic exec_jump, jump_set_nop;
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
rv32_word dec_reg1, dec_reg2, wb_data;
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
logic fetch_stall;
rv32_fetch_stage fetch_stage(
    .clk(clk), .resetn(resetn),
    // Pipeline I/O
    .stop(dec_stall | mem_stall),
    .set_nop(jump_set_nop),
    .set_nop_pc(jump_nop_pc),
    .pc(pc),
    .stall(fetch_stall),
    .fetch_decode_buff(fetch_decode_buff),
    // INSTR MEM I/O
    .instr_request(instr_request),
    .instr_response(instr_response)
);

// DECODE STAGE
logic dec_stall;
rv32_decode_stage decode_stage(
    .clk(clk), .resetn(resetn),
    // Pipeline I/O
    .set_nop(jump_set_nop),
    .set_nop_pc(jump_nop_pc),
    .fetch_decode_buff(fetch_decode_buff),
    .decode_exec_buff(decode_exec_buff),
    .stall(dec_stall),
    .stop(mem_stall),
    // Register file read I/O
    .rs1(dec_rs1), .rs2(dec_rs2),
    .reg1(dec_reg1), .reg2(dec_reg2),
    // Hazzard detection
    .exec_mem_buff(exec_mem_buff)
);

// EXECUTION STAGE
rv32_exec_stage exec_stage(
    .clk(clk), .resetn(resetn),
    .decode_exec_buff(decode_exec_buff),
    .exec_mem_buff(exec_mem_buff),
    .stop(mem_stall),
    .do_jump(exec_jump),
    .jump_addr(exec_jump_addr),
    .mem_wb_buff(mem_wb_buff)
);

// MEMORY STAGE
logic mem_stall;
rv32_mem_stage mem_stage(
    .clk(clk), .resetn(resetn),
    .exec_mem_buff(exec_mem_buff),
    .mem_wb_buff(mem_wb_buff),
    .stall(mem_stall),
    // Data Memory I/O
    .data_request(data_request),
    .data_response(data_response)
);

// WRITEBACK STAGE
rv32_wb_stage wb_stage(
    .mem_wb_buff(mem_wb_buff),
    .reg_write(wb_we), .rd(wb_rd), .wb_data(wb_data)
);

endmodule
