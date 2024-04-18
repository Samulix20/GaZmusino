/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_core (
    // Clk, Reset signals
    input logic clk, resetn,

    // Instructions memory port
    output rv32_word instr_addr,
    input rv_instr_t instr_bus,
    input logic instr_ready,

    // Debug ports
    output rv32_word pc,
    output fetch_buffer_data_t instr_buff_data,
    output decoded_buffer_data_t decoded_buff_data,
    output exec_buffer_data_t exec_buff_data
);

// PC logic
logic exec_jump;
rv32_word exec_jump_addr;

always_ff @(posedge clk) begin
    if (!resetn) begin
        pc <= 0;
    end else begin
        if(exec_jump) begin
            pc <= exec_jump_addr;
        end else begin
            pc <= pc + 4;
        end
    end
end

// Register file
rv_reg_id_t rs1, rs2;
rv32_word reg1, reg2;
rv32_register_file rf(
    .clk(clk), .resetn(resetn),
    // Decode interface
    .r1(rs1), .o1(reg1), .r2(rs2), .o2(reg2),
    // Writeback interface
    .write(0), .d(0), .rw(0)
);

// FETCH STAGE
logic fetch_stall;
rv32_fetch_stage fetch_stage(
    .clk(clk), .resetn(resetn),
    // Pipeline I/O
    .pc(pc),
    .stall(fetch_stall), .fetch_data(instr_buff_data),
    // INSTR MEM I/O
    .addr(instr_addr), .instr(instr_bus),
    .ready(instr_ready)
);

// DECODE STAGE
logic decode_stall;
rv32_decode_stage decode_stage(
    .clk(clk), .resetn(resetn),
    // Pipeline I/O
    .instr_data(instr_buff_data),
    .decode_data(decoded_buff_data),
    .stall(decode_stall),
    // Register file read I/O
    .rs1(rs1), .rs2(rs2),
    .reg1(reg1), .reg2(reg2)
);

// EXECUTION STAGE
rv32_exec_stage exec_stage(
    .clk(clk), .resetn(resetn),
    .decoded_data(decoded_buff_data),
    .exec_data(exec_buff_data),
    .do_jump(exec_jump),
    .jump_addr(exec_jump_addr)
);

endmodule
