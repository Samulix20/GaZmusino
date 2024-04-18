/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_fetch_buffer (
    // Clk, Reset signals
    input logic clk, resetn,

    // Core I/O
    input rv32_word pc,
    output logic stall,
    output fetch_buffer_data_t fetch_data,

    // Bus I/O
    output rv32_word addr,
    input rv_instr_t instr,
    input logic ready
);

always_ff @(posedge clk) begin
    if (!resetn) begin
        fetch_data.pc <= 0;
        fetch_data.instr <= `RV_NOP;
    end

    else begin
        if (ready) begin
            fetch_data.pc <= pc;
            fetch_data.instr <= instr;
        end

        else begin
            // NOP bubble
            fetch_data.instr <= `RV_NOP;
        end
    end
end

always_comb begin
    addr = pc;
    stall = ~ready;
end

endmodule
