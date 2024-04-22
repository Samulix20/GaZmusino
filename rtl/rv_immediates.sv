`ifndef RV_IMMEDIATES
`define RV_IMMEDIATES

`include "rtl/rv32_types"

function automatic rv32_word decode_i_imm(input rv32_word instr);
    rv32_word imm;
    imm[31:11] = '{default: instr[31]};
    imm[10:0] = instr[30:20];
    return imm;
endfunction

function automatic rv32_word decode_s_imm(input rv32_word instr);
    rv32_word imm;
    imm[31:11] = '{default: instr[31]};
    imm[10:5] = instr[30:25];
    imm[4:0] = instr[11:7];
    return imm;
endfunction

function automatic rv32_word decode_b_imm(input rv32_word instr);
    rv32_word imm;
    imm[31:12] = '{default: instr[31]};
    imm[11] = instr[7];
    imm[10:5] = instr[30:25];
    imm[4:1] = instr[11:8];
    imm[0] = 0;
    return imm;
endfunction

function automatic rv32_word decode_u_imm(input rv32_word instr);
    rv32_word imm;
    imm[31:12] = instr[31:12];
    imm[11:0] = '{default: 0};
    return imm;
endfunction

function automatic rv32_word decode_j_imm(input rv32_word instr);
    rv32_word imm;
    imm[31:20] = '{default: instr[31]};
    imm[19:12] = instr[19:12];
    imm[11] = instr[20];
    imm[10:1] = instr[30:21];
    imm[0] = 0;
    return imm;
endfunction

`endif
