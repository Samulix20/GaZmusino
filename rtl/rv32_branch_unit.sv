`ifndef RV_BRANCH_UNIT
`define RV_BRANCH_UNIT

typedef enum data_type {
    OP_BEQ = 4'b0000,
    OP_BNE = 4'b0001,
    OP_BLT = 4'b0100,
    OP_BGE = 4'b0101,
    OP_BLTU = 4'b0110,
    OP_BGEU = 4'b0111,
    OP_J = 4'b1000,
    OP_NOP = 4'b1111
} branch_op_t;

module rv32_branch_unit (
    input rv32_word op1, op2,
    input branch_op_t branch_op,
    output logic do_branch
);

logic eq, lt, ltu;

// Comparators
always_comb begin
    eq = (op1 == op2);
    lt = ($signed(op1) < $signed(op2));
    ltu = (op1 < op2);
end

// Branch decision
always_comb begin
    case (branch_op)
        OP_BEQ: do_branch = eq;
        OP_BNE: do_branch = ~eq;
        OP_BLT: do_branch = lt;
        OP_BGE: do_branch = ~lt;
        OP_BLTU: do_branch = ltu;
        OP_BGEU: do_branch = ~ltu;
        OP_J: do_branch = 1;
        default: do_branch = 0;
    endcase
end

endmodule

`endif
