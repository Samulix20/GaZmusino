`ifndef RV_DECODER
`define RV_DECODER

`include "rtl/rv32_types.sv"

typedef enum logic [6:0] {
    OPCODE_LUI = 7'b0110111,
    OPCODE_AUIPC = 7'b0010111,
    OPCODE_JAL = 7'b1101111,
    OPCODE_JARL = 7'b1100111,
    OPCODE_BRANCH = 7'b1100011,
    OPCODE_LOAD = 7'b0000011,
    OPCODE_STORE = 7'b0100011,
    OPCODE_INTEGER_IMM = 7'b0010011,
    OPCODE_INTEGER_REG = 7'b0110011,
    OPCODE_ZICSR = 7'b1110011,
    OPCODE_BARRIER = 7'b0001111
} valid_opcodes_t /*verilator public*/;

typedef enum logic [2:0] {
    INSTR_R_TYPE,
    INSTR_I_TYPE,
    INSTR_S_TYPE,
    INSTR_B_TYPE,
    INSTR_U_TYPE,
    INSTR_J_TYPE
} instr_type_t /*verilator public*/;

typedef struct packed {
    instr_t instr;
    instr_type_t t;
    logic compressed;
    logic invalid;
} decoded_instr_t;

module rv32_instruction_decoder (
    input   instr_t instr,
    output  decoded_instr_t o
);

// Return the instruction
always_comb begin
    o.instr = instr;
end

// Instruction type detection
always_comb begin
    if (
        instr.opcode == OPCODE_INTEGER_REG ||
        instr.opcode == OPCODE_JARL ||
        instr.opcode == OPCODE_LOAD
    ) begin
        o.t = INSTR_I_TYPE;
    end

    else if (
        instr.opcode == OPCODE_LUI ||
        instr.opcode == OPCODE_AUIPC
    ) begin
        o.t = INSTR_U_TYPE;
    end

    else if (instr.opcode == OPCODE_JAL) begin
        o.t = INSTR_J_TYPE;
    end

    else if (instr.opcode == OPCODE_STORE) begin
        o.t = INSTR_S_TYPE;
    end

    else if (instr.opcode == OPCODE_BRANCH) begin
        o.t = INSTR_B_TYPE;
    end

    else begin
        o.t = INSTR_R_TYPE;
    end
end

// Check compression
// TODO support compresion (C extension)
always_comb begin
    if (instruction.opcode[1:0] != 2'b00) begin
        o.compressed = 1;
    end else begin
        o.compressed = 0;
    end
end

// Invalid instruction detection
always_comb begin
    if (!(instruction.opcode inside {
        7'b0110111, 7'b0010111, 7'b1101111, 7'b1100111, 7'b1100011,
        7'b0000011, 7'b0100011, 7'b0010011, 7'b0110011, 7'b1110011,
        7'b0001111
    })) begin
        o.invalid = 1;
    end

    else begin
        o.invalid = 0;
    end
end

endmodule

`endif
