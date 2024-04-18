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

// FETCH STAGE
// PC logic
always_ff @(posedge clk) begin
    if (!resetn) begin
        pc <= 0;
    end else begin
        pc <= pc + 4;
    end
end

// Instruction buffer
logic fetch_stall;
rv32_fetch_stage fetch_stage(
    .clk(clk), .resetn(resetn),
    // CORE I/O
    .pc(pc),
    .stall(fetch_stall), .fetch_data(instr_buff_data),
    // INSTR MEM I/O
    .addr(instr_addr), .instr(instr_bus),
    .ready(instr_ready)
);

// DECODE STAGE
decoded_buffer_data_t decode_stage_output;

// Decode logic
rv32_instr_decoder decoder(
    .instr(instr_buff_data.instr),
    .decoded_instr(decode_stage_output.decoded_instr)
);

// Register file
rv32_register_file rf(
    .clk(clk), .resetn(resetn),
    .r1(instr_buff_data.instr.rs1), .o1(decode_stage_output.reg1),
    .r2(instr_buff_data.instr.rs2), .o2(decode_stage_output.reg2),
    .write(0), .d(0), .rw(0)
);

always_comb begin
    decode_stage_output.instr = instr_buff_data.instr;
    decode_stage_output.pc = instr_buff_data.pc;
    decoded_buff_data = decode_stage_output;
end

// EXECUTION STAGE
/*
rv32_int_alu int_alu(
    .op1(op1), .op2(op2), .opsel(alu_op),
    .result(result)
);
*/

endmodule
