#ifndef RV32_TEST_UTILS
#define RV32_TEST_UTILS

#include <elf.h>

#include <cassert>
#include <cstdlib>
#include <cstdio>

#include <memory>
#include <fstream>

uint32_t read_rv32_instr(const uint8_t* code, const uint32_t addr) {
    return *reinterpret_cast<const uint32_t*>(code + addr);
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