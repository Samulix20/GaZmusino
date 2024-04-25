/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_fetch_stage (
    // Clk, Reset signals
    input logic clk, resetn,

    // Core I/O
    input logic set_nop,
    input logic stop,
    input rv32_word set_nop_pc,

    input rv32_word pc,
    output logic stall,
    output fetch_decode_buffer_t fetch_decode_buff,

    // Bus I/O
    output memory_request_t instr_request,
    input memory_response_t instr_response
);

fetch_decode_buffer_t internal_data;

always_comb begin
    instr_request.addr = pc;
    instr_request.op = MEM_LW;
    instr_request.data = 0;
end

always_comb begin
    stall = ~instr_response.ready;

    // Default
    internal_data = fetch_decode_buff;
    internal_data.instr = `RV_NOP;

    // New instruction fetched
    if (instr_response.ready) begin
        internal_data.pc = pc;
        internal_data.instr = instr_response.data;
    end

    // Some instruction further in the pipeline is stalling
    if (stop) begin
        internal_data = fetch_decode_buff;
    end

    // Output a NOP
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
    fetch_decode_buff <= internal_data;
end

endmodule
