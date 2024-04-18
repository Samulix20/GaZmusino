/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_decode_stage (
    // Clk, Reset signals
    input logic clk, resetn,
    // Pipeline I/O
    input fetch_buffer_data_t instr_data,
    output decoded_buffer_data_t decode_data,
    // Register file read I/O
    output rv_reg_id_t rs1, rs2,
    input rv32_word reg1, reg2
);

decoded_buffer_data_t internal_data;

// Decode logic
rv32_instr_decoder decoder(
    .set_nop(~resetn),
    .instr(instr_data.instr),
    .decoded_instr(internal_data.decoded_instr)
);

always_comb begin
    // Forward signals
    internal_data.pc = instr_data.pc;
    internal_data.instr = instr_data.instr;
    // Register file data
    rs1 = instr_data.instr.rs1;
    rs2 = instr_data.instr.rs2;
    internal_data.reg1 = reg1;
    internal_data.reg2 = reg2;
end

always_ff @(posedge clk) begin
    decode_data <= internal_data;
end

endmodule
