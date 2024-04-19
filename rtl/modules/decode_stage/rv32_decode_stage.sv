/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_decode_stage (
    // Clk, Reset signals
    input logic clk, resetn,
    // Pipeline I/O
    input logic set_nop,
    input rv32_word set_nop_pc,
    input fetch_buffer_data_t instr_data,
    output decoded_buffer_data_t decode_data,
    output logic stall,
    // Register file read I/O
    output rv_reg_id_t rs1, rs2,
    input rv32_word reg1, reg2
);

decoded_buffer_data_t internal_data /*verilator public*/;
decoded_instr_t decoder_output;

rv32_decoder decoder(
    .instr(instr_data.instr),
    .decoded_instr(decoder_output)
);

// Decode logic
always_comb begin
    // Forward signals
    internal_data.pc = instr_data.pc;
    internal_data.instr = instr_data.instr;

    // Register file data
    rs1 = instr_data.instr.rs1;
    rs2 = instr_data.instr.rs2;
    internal_data.reg1 = reg1;
    internal_data.reg2 = reg2;

    // Default decode
    internal_data.decoded_instr = decoder_output;

    if(set_nop | !resetn) begin
        internal_data.instr = `RV_NOP;
        internal_data.pc = set_nop_pc;
        internal_data.decoded_instr = create_nop_ctrl();
    end

    // TODO make hazzard detection
    stall = 0;
end

always_ff @(posedge clk) begin
    decode_data <= internal_data;
end

endmodule
