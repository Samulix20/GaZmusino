#ifndef RV32_TEST_UTILS
#define RV32_TEST_UTILS

#include <elf.h>

#include <cassert>
#include <cstdlib>
#include <cstdio>

#include <memory>
#include <fstream>
#include <unordered_map>

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
    return str;
}

std::string wb_str(rv_instr_t instr, rv_decoded_instr_t dec_instr) {
    std::string s = "";
    if (dec_instr.register_wb) {
        s = "x" + std::to_string(instr.rd) + " <- ";
    }
    return s;
}

void get_decode_stage_data(Vrv32_core* rvcore) {
    decode_data_t d;
    d.set(rvcore->rv32_core->decode_stage->internal_data);
    std::string s = alu_op_str(d.decoded_instr) + " ";
    s += alu_input_str(d.instr, d.decoded_instr);
    printf("%s ALU {%s} BU {%s} %s|", 
        opcode_str(d.instr).c_str(), 
        s.c_str(), 
        branch_op_str(d.decoded_instr).c_str(),
        wb_str(d.instr, d.decoded_instr).c_str()
    );
}

void get_exec_stage_data(Vrv32_core* rvcore) {
    exec_data_t d;
    d.set(rvcore->rv32_core->exec_stage->internal_data);
    printf("%08x %08x | ", d.pc, d.instr);
}

void get_mem_stage_data(Vrv32_core* rvcore) {
    mem_data_t d;
    d.set(rvcore->rv32_core->mem_stage->internal_data);
    printf("%08x %08x | ", d.pc, d.instr);
}

void get_wb_stage_data(Vrv32_core* rvcore) {
    wb_data_t d;
    d.set(rvcore->rv32_core->mem_buff_data);
    if(d.wb_result) {
        printf("x%u <- %08x", d.instr.rd, d.wb_result);
    }
}


uint32_t read_instr(const uint8_t* code, const uint32_t addr) {
    return *reinterpret_cast<const uint32_t*>(code + addr);
}

uint8_t* read_elf(const char* filename) {
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
