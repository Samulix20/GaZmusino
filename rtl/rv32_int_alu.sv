`ifndef RV_INT_ALU
`define RV_INT_ALU

`include "rtl/rv32_types"

// SLT set less than
// SLL shift left logical
// SRL shift right logical
// SRA shift right arithmetic

typedef enum logic [3:0] {
    ALU_OP_ADD  = 4'b0000,
    ALU_OP_SLL  = 4'b0001,
    ALU_OP_SLT  = 4'b0010,
    ALU_OP_SLTU = 4'b0011,
    ALU_OP_XOR  = 4'b0100,
    ALU_OP_SRL  = 4'b0101,
    ALU_OP_OR   = 4'b0110,
    ALU_OP_AND  = 4'b0111,
    ALU_OP_SRA  = 4'b1000,
    ALU_OP_SUB  = 4'b1001,
    ALU_OP_SUBU = 4'b1111
} alu_opsel_t /*verilator public*/;

typedef enum logic [1:0] {
    CMP_Z, CMP_N, CMP_P
} cmp_flags_t /*verilator public*/;

typedef struct packed {
    rv32_word op1;
    rv32_word op2;
    alu_opsel_t operation;
} rv32_int_alu_operation /*verilator public*/;

module rv32_int_alu (
    input rv32_int_alu_operation i,
    output rv32_word result,
    output cmp_flags_t flags
);

rv32_word adder_res;
logic slt_res;
always_comb begin
    // 33 bit adder
    logic[32:0] op1_33, op2_33, adder_33;
    
    // Signed / Unsigned set
    if (i.operation inside {ALU_OP_SLTU, ALU_OP_SUBU}) begin
        // unsigned
        op1_33 = {1'b0, i.op1};
        op2_33 = {1'b0, i.op2};
    end else begin
        // signed
        op1_33 = {op1[31], i.op1};
        op2_33 = {op2[31], i.op2};
    end

    // 2's compliment negative
    // SUB operation
    if (i.operation inside {
        ALU_OP_SUB, ALU_OP_SUBU, 
        ALU_OP_SLT, ALU_OP_SLTU
    }) begin
        op2_33 = (~op2_33) + 1;
    end 
    
    // Only one Adder
    // op2 is -op2 is necesary
    adder_33 = op1_33 + op2_33;

    // Get CMP flags
    if (adder_33 == 0) begin
        flags = CMP_Z;
    end else if (adder_33[32] == 1) begin
        flags = CMP_N;
    end else begin
        flags = CMP_P;
    end

    // Get 32 lower bits
    adder_res = adder_33[31:0];

    // SLT Logic
    if (flags == CMP_N) begin
        slt_res = 1;
    end else begin
        slt_res = 0;
    end
end

always_comb begin
    case (i.operation)
        ALU_OP_ADD, ALU_OP_SUB: result = adder_res;
        ALU_OP_SLL: result = op1 << op2;
        ALU_OP_SLT, ALU_OP_SLTU: result = '{default: slt_res};
        ALU_OP_XOR: result = op1 ^ op2;
        ALU_OP_SRL: result = op1 >> op2;
        ALU_OP_OR: result = op1 | op2;
        ALU_OP_AND: result = op1 & op2;
        ALU_OP_SRA: result = $signed(op1) >>> op2;
        default: result = 0;
    endcase
end

endmodule

`endif
