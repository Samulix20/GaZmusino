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
    output decoded_buffer_data_t decoded_buff_data
);

// PC logic
always_ff @(posedge clk) begin
    if (!resetn) begin
        pc <= 0;
    end else begin
        pc <= pc + 4;
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
rv32_decode_stage decode_stage(
    .clk(clk), .resetn(resetn),
    // Pipeline I/O
    .instr_data(instr_buff_data),
    .decode_data(decoded_buff_data),
    // Register file read I/O
    .rs1(rs1), .rs2(rs2),
    .reg1(reg1), .reg2(reg2)
);

// EXECUTION STAGE
/*
rv32_int_alu int_alu(
    .op1(op1), .op2(op2), .opsel(alu_op),
    .result(result)
);
*/

endmodule
