/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_instr_decoder"
`include "rtl/rv32_register_file"
`include "rtl/rv32_int_alu"

module rv32_core (
    // Clk, Reset signals
    input logic clk, resetn,

    // Instructions memory port
    input rv_instr_t fetch_instr,
    output rv32_word pc
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

// DECODE STAGE
decoded_instr_t decoded_instr;

// Decode logic
rv32_instr_decoder decoder(
    .instr(fetch_instr),
    .decoded_instr(decoded_instr)
);

// Register file
rv32_word o1, o2;
rv32_register_file rf(
    .clk(clk), .resetn(resetn), .write(0),
    .r1(fetch_instr.rs1), .r2(fetch_instr.rs2),
    .rw(fetch_instr.rd), .d(0), .o1(o1), .o2(o2)
);

// EXECUTION STAGE
/*
rv32_int_alu int_alu(
    .op1(op1), .op2(op2), .opsel(alu_op),
    .result(result)
);
*/

endmodule
