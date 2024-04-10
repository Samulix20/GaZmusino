/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/riscv_register_file.sv"

typedef enum logic [6:0] {
	OPCODE_LUI = 7'b0110111,
	OPCODE_AUIPC = 7'b0010111,
	OPCODE_JAL = 7'b1101111,
	OPCODE_JARL = 7'b1100111,
	OPCODE_BRANCH = 7'b1100011,
	OPCODE_LOAD = 7'b0000011,
	OPCODE_STORE = 7'b0100011,
	OPCODE_INTEGER_REG = 7'b0010011,
	OPCODE_INTEGER_IMM = 7'b0110011,
	OPCODE_ZICSR = 7'b1110011,
	OPCODE_BARRIER = 7'b0001111
} valid_opcodes_t;

typedef logic [6:0] opcode_t;
typedef logic [31:0] immediate_t;

typedef struct packed {
	logic [6:0] funct7;	// [31:25]
	reg_id_t rs2;		// [24:20]
	reg_id_t rs1; 		// [19:15]
	logic [2:0] funct3;	// [14:12]
	reg_id_t rd;		// [11:7]
	opcode_t opcode;	// [6:0]
} default_decoded_rv_instr_t;


module riscv_decoder (
	input	logic clk, resetn,
	input	logic [31:0] instruction
);

// Default decode
default_decoded_rv_instr_t default_decode;
always_comb begin
	default_decode = instruction;
end

// Immediate generation
immediate_t i_imm, s_imm, b_imm, u_imm, j_imm;
always_comb begin 
	i_imm[31:11] = '{default: instruction[31]};
	i_imm[10:0] = instruction[30:20];

	s_imm[31:11] = '{default: instruction[31]};
	s_imm[10:5] = instruction[30:25];
	s_imm[4:0] = instruction[11:7];

	b_imm[31:12] = '{default: instruction[31]};
	b_imm[11] = instruction[7];
	b_imm[10:5] = instruction[30:25];
	b_imm[4:1] = instruction[11:8];
	b_imm[0] = 0;

	u_imm[31:12] = instruction[31:12];
	u_imm[11:0] = '{default: instruction[0]};

	j_imm[31:20] = '{default: instruction[31]};
	j_imm[19:12] = instruction[19:12];
	j_imm[11] = instruction[20];
	j_imm[10:1] = instruction[30:21];
	j_imm[0] = 0;
end

logic [31:0] a, b;
riscv_register_file rf (
	.clk(clk), .resetn(resetn),
	.r1(default_decode.rs1),
	.r2(default_decode.rs2),
	.rw(0), .d(0), .write(0),
	.o1(a), .o2(b)
);

endmodule

