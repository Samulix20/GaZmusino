/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_instruction_decoder"
`include "rtl/rv32_register_file"

module rv32_core (
    input logic clk, resetn,
    input instr_t instruction,
    output rv32_word pc
);

logic a;
instr_type_t t;
decoded_instr_t d;

// PC logic
always_ff @(posedge clk) begin
    if (!resetn) begin
        pc <= 0;
    end else begin
        pc <= pc + 4;
    end
end

// Decode logic
rv32_instruction_decoder decoder(
    .instr(instruction),
    .o(d)
);

// Register file
rv32_word o1, o2;
rv32_register_file rf(
    .clk(clk), .resetn(resetn), .write(0),
    .r1(instruction.rs1), .r2(instruction.rs2),
    .rw(instruction.rd), .d(0), .o1(o1), .o2(o2)
);

endmodule
