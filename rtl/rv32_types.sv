`ifndef RV_32_TYPES
`define RV_32_TYPES

typedef logic[31:0] rv32_word;

typedef logic [4:0] reg_id_t;

typedef logic [6:0] opcode_t;

function rv32_word decode_i_imm(rv32_word instr);
    rv32_word imm;
    imm[31:11] = '{default: instr[31]};
    imm[10:0] = instr[30:20];
    return imm;
endfunction

function rv32_word decode_s_imm(rv32_word instr);
    rv32_word imm;
    imm[31:11] = '{default: instr[31]};
    imm[10:5] = instr[30:25];
    imm[4:0] = instr[11:7];
    return imm;
endfunction

function rv32_word decode_b_imm(rv32_word instr);
    rv32_word imm;
    imm[31:12] = '{default: instr[31]};
    imm[11] = instr[7];
    imm[10:5] = instr[30:25];
    imm[4:1] = instr[11:8];
    imm[0] = 0;
    return imm;
endfunction

function rv32_word decode_u_imm(rv32_word instr);
    rv32_word imm;
    imm[31:12] = instr[31:12];
    imm[11:0] = '{default: instr[0]};
    return imm;
endfunction

function rv32_word decode_j_imm(rv32_word instr);
    rv32_word imm;
    imm[31:20] = '{default: instr[31]};
    imm[19:12] = instr[19:12];
    imm[11] = instr[20];
    imm[10:1] = instr[30:21];
    imm[0] = 0;
    return imm;
endfunction

// Decoding defaults to R-Type
typedef struct packed {
    logic [6:0] funct7;     // [31:25]
    reg_id_t rs2;           // [24:20]
    reg_id_t rs1;           // [19:15]
    logic [2:0] funct3;     // [14:12]
    reg_id_t rd;            // [11:7]
    opcode_t opcode;        // [6:0]
} instr_t /*verilator public*/;

`endif
