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
    output memory_request_t instr_request,
    input memory_response_t instr_response
);

fetch_buffer_data_t internal_data;

always_comb begin
    instr_request.addr = pc;
    instr_request.op = MEM_LW;
    instr_request.data = 0;

    stall = ~instr_response.ready;

    // Default
    internal_data = fetch_data;
    internal_data.instr = `RV_NOP;

    // New instruction fetched
    if (instr_response.ready) begin
        internal_data.pc = pc;
        internal_data.instr = instr_response.data;
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
