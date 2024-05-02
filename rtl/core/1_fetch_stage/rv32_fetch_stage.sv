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
    input logic request_done
);

fetch_decode_buffer_t internal_data;

always_comb begin
    if (stop) instr_request.op = MEM_NOP;
    else instr_request.op = MEM_LW;

    instr_request.addr = pc;
    instr_request.data = 0;
    stall = ~request_done;
end

always_ff @(posedge clk) begin
    if (!resetn) begin
        fetch_decode_buff.pc <= 0;
        fetch_decode_buff.generate_nop <= 1;
    end

    // A instruction is flushing the pipeline
    else if (set_nop) begin
        fetch_decode_buff.pc <= set_nop_pc;
        fetch_decode_buff.generate_nop <= 1;
    end

    // Some instruction further in the pipeline is stalling do nothing
    else if (!stop) begin
        // Memory request is done, new instruction fetched
        if (request_done) begin
            fetch_decode_buff.pc <= pc;
            fetch_decode_buff.generate_nop <= 0;
        end
    end

end

endmodule
