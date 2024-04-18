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
    output decoded_instr_t decoded_instr
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
rv32_fetch_buffer fetch_buff(
    .clk(clk), .resetn(resetn),
    .pc(pc), .stall(fetch_stall),
    .fetch_data(instr_buff_data),
    .addr(instr_addr), .instr(instr_bus),
    .ready(instr_ready)
);

// DECODE STAGE
// Decode logic
rv32_instr_decoder decoder(
    .instr(instr_buff_data.instr),
    .decoded_instr(decoded_instr)
);

// Register file
rv32_word o1, o2;
rv32_register_file rf(
    .clk(clk), .resetn(resetn), .write(0),
    .r1(instr_buff_data.instr.rs1), .r2(instr_buff_data.instr.rs2),
    .rw(instr_buff_data.instr.rd), .d(0), .o1(o1), .o2(o2)
);

// EXECUTION STAGE
/*
rv32_int_alu int_alu(
    .op1(op1), .op2(op2), .opsel(alu_op),
    .result(result)
);
*/

endmodule
