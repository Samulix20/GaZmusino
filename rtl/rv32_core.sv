/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_instruction_decoder"
`include "rtl/rv32_register_file"
`include "rtl/rv32_int_alu"

module rv32_core (
    input logic clk, resetn,
    input instr_t instruction,
    output rv32_word pc,

    input rv32_word op1, op2,
    input alu_opsel_t alu_op,
    output rv32_word result
);

// PC logic
always_ff @(posedge clk) begin
    if (!resetn) begin
        pc <= 0;
    end else begin
        pc <= pc + 4;
    end
end

/*
logic a;
instr_type_t t;

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
*/

rv32_int_alu int_alu(
    .op1(op1), .op2(op2), .opsel(alu_op),
    .result(result)
);

endmodule
