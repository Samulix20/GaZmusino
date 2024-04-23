#ifndef RV32_TEST_UTILS
#define RV32_TEST_UTILS

#include <elf.h>

#include <cassert>
#include <cstdlib>
#include <cstdio>

#include <memory>
#include <fstream>
#include <unordered_map>
#include <format>

// Device under test header
#include "Vrv32_core.h"
#include "Vrv32_core_rv32_core.h"
#include "Vrv32_core_rv32_decode_stage.h"
#include "Vrv32_core_rv32_exec_stage.h"
#include "Vrv32_core_rv32_mem_stage.h"
#include "Vrv32_core___024unit.h"

namespace rv32_test {

using decode_data_t = Vrv32_core_decoded_buffer_data_t__struct__0;
using exec_data_t = Vrv32_core_exec_buffer_data_t__struct__0;
using mem_data_t = Vrv32_core_mem_buffer_data_t__struct__0;
using wb_data_t = mem_data_t;
using memory_request_t = Vrv32_core_memory_request_t__struct__0;
using memory_response_t = Vrv32_core_memory_response_t__struct__0;

using rv_instr_t = Vrv32_core_rv_instr_t__struct__0;
using rv_decoded_instr_t = Vrv32_core_decoded_instr_t__struct__0;
using RV32Core = Vrv32_core___024unit;

std::string opcode_str(rv_instr_t instr) {
    std::string str;
    static const std::unordered_map<RV32Core::valid_opcodes_t, std::string> str_map = {
        {RV32Core::OPCODE_LUI, "LUI"},
        {RV32Core::OPCODE_AUIPC, "AUIPC"},
        {RV32Core::OPCODE_JAL, "JAL"},
        {RV32Core::OPCODE_JALR, "JALR"},
        {RV32Core::OPCODE_BRANCH, "BRANCH"},
        {RV32Core::OPCODE_LOAD, "LOAD"},
        {RV32Core::OPCODE_STORE, "STORE"},
        {RV32Core::OPCODE_INTEGER_IMM, "INT IMM"},
        {RV32Core::OPCODE_INTEGER_REG, "INT REG"},
        {RV32Core::OPCODE_ZICSR, "ZICSR"},
        {RV32Core::OPCODE_BARRIER, "BARRIER"}
    };
    auto it = str_map.find(static_cast<RV32Core::valid_opcodes_t>(instr.opcode));
    if (it != str_map.end()) str = it->second;
    else str = "???";
    return str;
}

std::string bypass_str(rv_instr_t instr, rv_decoded_instr_t dec_instr) {
    static const std::unordered_map<RV32Core::bypass_t, std::string> str_map = {
        {RV32Core::NO_BYPASS, "NO"},
        {RV32Core::BYPASS_EXEC_BUFF, "EXEC"},
        {RV32Core::BYPASS_MEM_BUFF, "MEM"}
    };

    std::string s = "";

    for (uint32_t i = 0; i < 2; i++) {
        RV32Core::bypass_t bypass;
        std::string rs, b_op;

        if (i == 0) {
            bypass = static_cast<RV32Core::bypass_t>(dec_instr.bypass_rs1);
            rs = "rs1(x" + std::to_string(instr.rs1) + ")";
        } else {
            bypass = static_cast<RV32Core::bypass_t>(dec_instr.bypass_rs2);
            rs = "rs2(x" + std::to_string(instr.rs2) + ")";
        }

        auto it = str_map.find(bypass);
        if (it != str_map.end()) b_op = it->second;
        else b_op = "NO";

        if (b_op == "NO") continue;

        s += "!" + b_op + " " + rs + " ";
    }

    return s;
}

std::string rename_imm_str(std::string op, rv_decoded_instr_t dec_instr) {
    static const std::unordered_map<RV32Core::instr_type_t, std::string> str_map = {
        {RV32Core::INSTR_R_TYPE, "???"},
        {RV32Core::INSTR_I_TYPE, "I_IMM"},
        {RV32Core::INSTR_S_TYPE, "S_IMM"},
        {RV32Core::INSTR_B_TYPE, "B_IMM"},
        {RV32Core::INSTR_U_TYPE, "U_IMM"},
        {RV32Core::INSTR_J_TYPE, "J_IMM"}
    };

    if (op != "IMM") return op;

    auto it = str_map.find(static_cast<RV32Core::instr_type_t>(dec_instr.t));
    if (it != str_map.end()) op = it->second;
    else op = "???";
    return op;
}

std::string alu_input_str(rv_instr_t instr, rv_decoded_instr_t dec_instr) {
    std::string op1, op2;
    static const std::unordered_map<RV32Core::int_alu_input_t, std::string> str_map = {
        {RV32Core::ALU_IN_ZERO, "0"},
        {RV32Core::ALU_IN_REG_1, "R1"},
        {RV32Core::ALU_IN_REG_2, "R2"},
        {RV32Core::ALU_IN_PC, "PC"},
        {RV32Core::ALU_IN_IMM, "IMM"}
    };
    auto it = str_map.find(static_cast<RV32Core::int_alu_input_t>(dec_instr.int_alu_i1));
    if (it != str_map.end()) op1 = it->second;
    else op1 = "???";

    if(op1 == "R1") op1 = "rs1(x" + std::to_string(instr.rs1) + ")";
    else if(op1 == "R2") op1 = "rs2(x" + std::to_string(instr.rs2) + ")";

    it = str_map.find(static_cast<RV32Core::int_alu_input_t>(dec_instr.int_alu_i2));
    if (it != str_map.end()) op2 = it->second;
    else op2 = " ???";

    if(op2 == "R1") op2 = "rs1(x" + std::to_string(instr.rs1) + ")";
    else if(op2 == "R2") op2 = "rs2(x" + std::to_string(instr.rs2) + ")";

    op1 = rename_imm_str(op1, dec_instr);
    op2 = rename_imm_str(op2, dec_instr);

    return op1 + " " + op2;
}

std::string alu_op_str(rv_decoded_instr_t instr) {
    std::string str;
    static const std::unordered_map<RV32Core::int_alu_op_t, std::string> str_map = {
        {RV32Core::ALU_OP_ADD, "ADD"},
        {RV32Core::ALU_OP_SLL, "SLL"},
        {RV32Core::ALU_OP_SLT, "SLT"},
        {RV32Core::ALU_OP_SLTU, "SLTU"},
        {RV32Core::ALU_OP_XOR, "XOR"},
        {RV32Core::ALU_OP_SRL, "SRL"},
        {RV32Core::ALU_OP_OR, "OR"},
        {RV32Core::ALU_OP_AND, "AND"},
        {RV32Core::ALU_OP_SRA, "SRA"},
        {RV32Core::ALU_OP_SUB, "SUB"}
    };
    auto it = str_map.find(static_cast<RV32Core::int_alu_op_t>(instr.int_alu_op));
    if (it != str_map.end()) str = it->second;
    else str = "???";
    return str;
}

// If jump != NOP "[BRANCH_OP]"
std::string branch_op_str(rv_decoded_instr_t instr) {
    std::string str;
    static const std::unordered_map<RV32Core::branch_op_t, std::string> str_map = {
        {RV32Core::OP_BEQ, "BEQ"},
        {RV32Core::OP_BNE, "BNE"},
        {RV32Core::OP_BLT, "BLT"},
        {RV32Core::OP_BGE, "BGE"},
        {RV32Core::OP_BLTU, "BLTU"},
        {RV32Core::OP_BGEU, "BGEU"},
        {RV32Core::OP_J, "J"},
        {RV32Core::OP_NOP, "NOP"}
    };
    auto it = str_map.find(static_cast<RV32Core::branch_op_t>(instr.branch_op));
    if (it != str_map.end()) str = it->second;
    else str = "???";
    if(str == "NOP") str = "";
    return str;
}

// If writeback "[WB_SRC] -> x[rd]"
std::string wb_src_str(rv_instr_t instr, rv_decoded_instr_t dec_instr) {
    std::string s = "";

    static const std::unordered_map<RV32Core::wb_result_t, std::string> str_map = {
        {RV32Core::WB_PC4, "PC4"},
        {RV32Core::WB_INT_ALU, "ALU"},
        {RV32Core::WB_MEM_DATA, "MEM"}
    };
    auto it = str_map.find(static_cast<RV32Core::wb_result_t>(dec_instr.wb_result_src));
    if (it != str_map.end()) s = it->second;
    else s = "???";

    if (dec_instr.register_wb) {
        s += " -> x" + std::to_string(instr.rd);
    } else {
        s = "";
    }

    return s;
}

// If writeback "x[rd] <- [wb_result]"
std::string wb_write_str(wb_data_t wbd) {
    std::string s = "";
    if (wbd.decoded_instr.register_wb) {
        s += "x" + std::to_string(wbd.instr.rd) + " <- " + std::format("{:<#10x}", wbd.wb_result);
    }
    return s;
}

decode_data_t get_decode_stage_data(Vrv32_core* rvcore) {
    decode_data_t d;
    d.set(rvcore->rv32_core->decode_stage->internal_data);
    return d;
}

exec_data_t get_exec_stage_data(Vrv32_core* rvcore) {
    exec_data_t d;
    d.set(rvcore->rv32_core->exec_stage->internal_data);
    return d;
}

mem_data_t get_mem_stage_data(Vrv32_core* rvcore) {
    mem_data_t d;
    d.set(rvcore->rv32_core->mem_stage->internal_data);
    return d;
}

wb_data_t get_wb_stage_data(Vrv32_core* rvcore) {
    wb_data_t d;
    d.set(rvcore->rv32_core->mem_buff_data);
    return d;
}

uint32_t get_next_pc(Vrv32_core* rvcore) {
    return rvcore->rv32_core->next_pc;
}

std::string decode_register_usage_str(Vrv32_core* rvcore) {
    std::string s = "";
    uint8_t usage = rvcore->rv32_core->decode_stage->use_rs;
    rv_instr_t instr = get_decode_stage_data(rvcore).instr;
    if(usage & 1) s += "rs1(x" + std::to_string(instr.rs1) + ") ";
    if(usage & 2) s += "rs2(x" + std::to_string(instr.rs2) + ") ";
    if(s != "") s = "Uses " + s;
    return s;
}

std::string mem_op_str(Vrv32_core* rvcore) {
    auto mem_data = get_mem_stage_data(rvcore);

    memory_request_t request;
    request.set(rvcore->data_request);

    std::string s = "";
    static const std::unordered_map<RV32Core::mem_op_t, std::string> str_map = {
        {RV32Core::MEM_LB, "LB"},
        {RV32Core::MEM_LH, "LH"},
        {RV32Core::MEM_LW, "LW"},
        {RV32Core::MEM_LBU, "LBU"},
        {RV32Core::MEM_LHU, "LHU"},
        {RV32Core::MEM_SB, "SB"},
        {RV32Core::MEM_SH, "SH"},
        {RV32Core::MEM_SW, "SW"},
        {RV32Core::MEM_NOP, "NO MEM"}
    };
    auto it = str_map.find(static_cast<RV32Core::mem_op_t>(request.op));
    if (it != str_map.end()) s = it->second;
    else s = "???";

    if (s == "NO MEM") s = "";
    else if (s[0] == 'S') {
        s = std::format("{} [{:#x}] <- {:#x}", s, request.addr, request.data);
    }

    return s;
}

class TraceCanvas {
  public:
    uint32_t stages;
    uint32_t lines;
    std::vector<std::vector<std::string>> canvas;

    TraceCanvas(uint32_t num_stages, uint32_t num_lines): stages(num_stages), lines(num_lines) {
        for(uint32_t i = 0; i < stages; i++) {
            auto s = std::vector<std::string>();
            for(uint32_t j = 0; j < lines; j++) {
                s.push_back("");
            }
            canvas.push_back(s);
        }
    }

    void print() {
        std::string s = "";
        for(uint32_t j = 0; j < lines; j++) {
            for(uint32_t i = 0; i < stages; i++) {
                s += std::format("|{:<30}", canvas[i][j]);
            }
            s += "|\n";
        }

        for(uint32_t i = 0; i < stages; i++) {
            s += std::format("|{:=^30}", "");
        }
        s += "|\n";
        std::cout << s;
    }
};

void trace_stages(Vrv32_core* rvcore) {
    auto tc = TraceCanvas(5, 4);
    
    memory_request_t instr_request;
    instr_request.set(rvcore->instr_request);
    memory_response_t instr_response;
    instr_response.set(rvcore->instr_response);

    tc.canvas[0][0] = std::format("@ {:<#10x} I {:<#10x}", instr_request.addr, instr_response.data);
    tc.canvas[0][1] = std::format("@ <- {:<#10x}", get_next_pc(rvcore));

    auto decode_data = get_decode_stage_data(rvcore);
    tc.canvas[1][0] = std::format("@ {:<#10x} I {:<#10x}", decode_data.pc, decode_data.instr.get());
    tc.canvas[1][1] = "Opcode " + opcode_str(decode_data.instr);
    tc.canvas[1][2] = decode_register_usage_str(rvcore);
    tc.canvas[1][3] = bypass_str(decode_data.instr, decode_data.decoded_instr);

    auto exec_data = get_exec_stage_data(rvcore);
    tc.canvas[2][0] = std::format("@ {:<#10x} I {:<#10x}", exec_data.pc, exec_data.instr.get());
    tc.canvas[2][1] = wb_src_str(exec_data.instr, exec_data.decoded_instr);
    tc.canvas[2][2] = alu_op_str(exec_data.decoded_instr) + " ";
    tc.canvas[2][2] += alu_input_str(exec_data.instr, exec_data.decoded_instr);
    tc.canvas[2][3] = branch_op_str(exec_data.decoded_instr);
    
    auto mem_data = get_mem_stage_data(rvcore);
    tc.canvas[3][0] = std::format("@ {:<#10x} I {:<#10x}", mem_data.pc, mem_data.instr.get());
    tc.canvas[3][1] = wb_src_str(mem_data.instr, mem_data.decoded_instr);
    tc.canvas[3][2] = mem_op_str(rvcore);

    auto wb_data = get_wb_stage_data(rvcore);
    tc.canvas[4][0] = std::format("@ {:<#10x} I {:<#10x}", wb_data.pc, wb_data.instr.get());
    tc.canvas[4][1] = wb_write_str(wb_data);

    tc.print();
}


uint32_t read_instr(const uint8_t* code, const uint32_t addr) {
    return *reinterpret_cast<const uint32_t*>(code + (addr & (~3)));
}

uint8_t* read_elf(std::string filename) {
    std::ifstream f(filename, std::ios::binary);
    // Check file is open
    assert(f.is_open());

    // Read header
    Elf32_Ehdr* ehdr = new Elf32_Ehdr;
    f.read(reinterpret_cast<char*>(ehdr), sizeof(*ehdr));

    // Check is a 32 bit elf file
    assert(ehdr->e_ident[EI_CLASS] == 1);
    // Check is for RISC-V
    assert(ehdr->e_machine == EM_RISCV);

    // Set fd to read program header
    // Seek and read segment 1 cause segment 0 is used for RV attributes
    Elf32_Phdr* phdr = new Elf32_Phdr;
    f.seekg(ehdr->e_phoff + sizeof(*phdr));
    f.read(reinterpret_cast<char*>(phdr), sizeof(*phdr));
    
    // Make sure its loadable
    assert(phdr->p_type == PT_LOAD);

    // Allocate memory of size in memory
    uint8_t* rv_program = new uint8_t[phdr->p_memsz];
    // Go to the segment data and read
    f.seekg(phdr->p_offset);
    // Copy only the data present in the ELF file
    f.read(reinterpret_cast<char*>(rv_program), phdr->p_filesz);
    f.close();

    return rv_program;
}

}

#endif
