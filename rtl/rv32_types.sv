`ifndef RV_32_TYPES
`define RV_32_TYPES

// Nop operation add x0 x0, 0 (0x00000033)
`define RV_NOP 'h33

typedef logic[31:0] rv32_word;

typedef logic [4:0] rv_reg_id_t;

typedef logic [6:0] opcode_t;

function automatic rv32_word decode_i_imm(rv32_word instr);
    rv32_word imm;
    imm[31:11] = '{default: instr[31]};
    imm[10:0] = instr[30:20];
    return imm;
endfunction

function automatic rv32_word decode_s_imm(rv32_word instr);
    rv32_word imm;
    imm[31:11] = '{default: instr[31]};
    imm[10:5] = instr[30:25];
    imm[4:0] = instr[11:7];
    return imm;
endfunction

function automatic rv32_word decode_b_imm(rv32_word instr);
    rv32_word imm;
    imm[31:12] = '{default: instr[31]};
    imm[11] = instr[7];
    imm[10:5] = instr[30:25];
    imm[4:1] = instr[11:8];
    imm[0] = 0;
    return imm;
endfunction

function automatic rv32_word decode_u_imm(rv32_word instr);
    rv32_word imm;
    imm[31:12] = instr[31:12];
    imm[11:0] = '{default: instr[0]};
    return imm;
endfunction

function automatic rv32_word decode_j_imm(rv32_word instr);
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
    rv_reg_id_t rs2;           // [24:20]
    rv_reg_id_t rs1;           // [19:15]
    logic [2:0] funct3;     // [14:12]
    rv_reg_id_t rd;            // [11:7]
    opcode_t opcode;        // [6:0]
} rv_instr_t /*verilator public*/;

typedef enum logic [6:0] {
    OPCODE_LUI = 7'b0110111,
    OPCODE_AUIPC = 7'b0010111,
    OPCODE_JAL = 7'b1101111,
    OPCODE_JALR = 7'b1100111,
    OPCODE_BRANCH = 7'b1100011,
    OPCODE_LOAD = 7'b0000011,
    OPCODE_STORE = 7'b0100011,
    OPCODE_INTEGER_IMM = 7'b0010011,
    OPCODE_INTEGER_REG = 7'b0110011,
    OPCODE_ZICSR = 7'b1110011,
    OPCODE_BARRIER = 7'b0001111
} valid_opcodes_t /*verilator public*/;

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
    ALU_OP_SUB  = 4'b1001
} int_alu_op_t /*verilator public*/;

typedef enum logic [3:0] {
    OP_BEQ = 4'b0000,
    OP_BNE = 4'b0001,
    OP_BLT = 4'b0100,
    OP_BGE = 4'b0101,
    OP_BLTU = 4'b0110,
    OP_BGEU = 4'b0111,
    OP_J = 4'b1000,
    OP_NOP = 4'b1111
} branch_op_t /*verilator public*/;

typedef enum logic [2:0] {
    INSTR_R_TYPE,
    INSTR_I_TYPE,
    INSTR_S_TYPE,
    INSTR_B_TYPE,
    INSTR_U_TYPE,
    INSTR_J_TYPE
} instr_type_t /*verilator public*/;

typedef enum logic [2:0]{
    ALU_IN_ZERO,
    ALU_IN_REG_1,
    ALU_IN_REG_2,
    ALU_IN_PC,
    ALU_IN_IMM
} int_alu_input_t /*verilator public*/;

typedef struct packed {
    rv_instr_t instr;
    rv32_word pc;
} fetch_buffer_data_t /*verilator public*/;

typedef struct packed {
    logic invalid;
    instr_type_t t;
    branch_op_t branch_op;
    int_alu_op_t int_alu_op;
    int_alu_input_t int_alu_i1;
    int_alu_input_t int_alu_i2;
    logic register_wb;
} decoded_instr_t /*verilator public*/;

typedef struct packed {
    rv_instr_t instr;
    rv32_word pc;
    decoded_instr_t decoded_instr;
    rv32_word reg1;
    rv32_word reg2;
} decoded_buffer_data_t /*verilator public*/;

`endif
