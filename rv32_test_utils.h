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

uint32_t read_rv32_instr(const uint8_t* code, const uint32_t addr) {
    return *reinterpret_cast<const uint32_t*>(code + addr);
}

using decode_data_t = Vrv32_core_decoded_buffer_data_t__struct__0;
using exec_data_t = Vrv32_core_exec_buffer_data_t__struct__0;
using mem_data_t = Vrv32_core_mem_buffer_data_t__struct__0;

using rv_instr_t = Vrv32_core_rv_instr_t__struct__0;
using RV32Arch = Vrv32_core___024unit;

void get_decode_stage_data(Vrv32_core* rvcore) {
    decode_data_t d;
    d.set(rvcore->rv32_core->decode_stage->internal_data);
    printf("%08x\n", d.pc);
}

void get_exec_stage_data(Vrv32_core* rvcore) {
    exec_data_t d;
    d.set(rvcore->rv32_core->exec_stage->internal_data);
    printf("%08x\n", d.pc);
}

void get_mem_stage_data(Vrv32_core* rvcore) {
    mem_data_t d;
    d.set(rvcore->rv32_core->mem_stage->internal_data);
    printf("%08x\n", d.pc);
}

std::string rv_instr_str(rv_instr_t instr) {
    std::string str;

    static const std::unordered_map<RV32Arch::valid_opcodes_t, std::string> opcode_str_map = {
        {RV32Arch::OPCODE_LUI, "LUI"},
        {RV32Arch::OPCODE_AUIPC, "AUIPC"},
        {RV32Arch::OPCODE_JAL, "JAL"},
        {RV32Arch::OPCODE_JALR, "JALR"},
        {RV32Arch::OPCODE_BRANCH, "BRANCH"},
        {RV32Arch::OPCODE_LOAD, "LOAD"},
        {RV32Arch::OPCODE_STORE, "STORE"},
        {RV32Arch::OPCODE_INTEGER_IMM, "INT IMM"},
        {RV32Arch::OPCODE_INTEGER_REG, "INT REG"},
        {RV32Arch::OPCODE_ZICSR, "ZICSR"},
        {RV32Arch::OPCODE_BARRIER, "BARRIER"}
    };

    auto it = opcode_str_map.find(static_cast<RV32Arch::valid_opcodes_t>(instr.opcode));
    if (it != opcode_str_map.end()) str = it->second;
    else str = "???";



    return str;
}

uint8_t* read_rv32_elf(const char* filename) {
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

#endif
