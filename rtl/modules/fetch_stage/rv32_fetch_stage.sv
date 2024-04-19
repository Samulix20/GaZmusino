/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_fetch_stage (
    // Clk, Reset signals
    input logic clk, resetn,

    // Core I/O
    input logic set_nop,
    input rv32_word set_nop_pc,

    input rv32_word pc,
    output logic stall,
    output fetch_buffer_data_t fetch_data,

    // Bus I/O
    output rv32_word addr,
    input rv_instr_t instr,
    input logic ready
);

fetch_buffer_data_t internal_data;

always_comb begin
    addr = pc;
    stall = ~ready;

    internal_data = fetch_data;
    internal_data.instr = `RV_NOP;

    // New instruction fetched
    if (ready) begin
        internal_data.pc = pc;
        internal_data.instr = instr;
    end

    if (set_nop) begin
        internal_data.pc = set_nop_pc;
        internal_data.instr = `RV_NOP;
    end

    if (!resetn) begin
        internal_data.pc = 0;
        internal_data.instr = `RV_NOP;
    end

end

always_ff @(posedge clk) begin
    fetch_data <= internal_data;
end

endmodule
