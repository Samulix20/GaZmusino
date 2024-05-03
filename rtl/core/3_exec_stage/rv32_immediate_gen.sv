/* verilator lint_off UNUSEDSIGNAL */

module rv32_immediate_gen
import rv32_types::*;
(
    input instr_type_t instr_type,
    input rv32_word instruction,
    output rv32_word immediate
);

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

always_comb begin
    case (instr_type)
        INSTR_I_TYPE: immediate = decode_i_imm(instruction);
        INSTR_S_TYPE: immediate = decode_s_imm(instruction);
        INSTR_B_TYPE: immediate = decode_b_imm(instruction);
        INSTR_U_TYPE: immediate = decode_u_imm(instruction);
        INSTR_J_TYPE: immediate = decode_j_imm(instruction);
        default: immediate = 0;
    endcase
end

endmodule
