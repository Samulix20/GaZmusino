/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_instr_decoder (
    input   logic set_nop,
    input   rv_instr_t instr,
    output  decoded_instr_t decoded_instr
);

// Check compression
// TODO support compresion (C extension)
logic compressed;
always_comb begin
    if (instr.opcode[1:0] != 2'b11) begin
        compressed = 1;
    end else begin
        compressed = 0;
    end
end

endmodule
