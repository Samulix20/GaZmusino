#ifndef RV_ELF_H
#define RV_ELF_H

#include <elf.h>
#include <stdio.h>
#include <inttypes.h>

#include <cassert>
#include <cstdlib>

uint8_t* read_rv32_elf(const char* filename) {
    FILE* fd = fopen(filename, "rb");
    // Check file is open
    assert(fd == NULL);

    // Read header
    Elf32_Ehdr* ehdr = new Elf32_Ehdr;
    fread((void *) ehdr, sizeof(Elf32_Ehdr), 1, fd);
    // Check is a 32 bit elf file
    assert(ehdr->e_ident[EI_CLASS] == 1);
    // Check is for RISC-V
    assert(ehdr->e_machine == EM_RISCV);

    // Set fd to read program header
    // Seek and read segment 1 cause segment 0 is used for RV attributes
    fseek(fd, ehdr->e_phoff + 1 * sizeof(Elf32_Phdr), SEEK_SET);
    Elf32_Phdr* phdr = new Elf32_Phdr;
    fread((void *) phdr, sizeof(Elf32_Phdr), 1, fd);
    // Make sure its loadable
    assert(phdr->p_type == PT_LOAD);

    // Allocate memory
    uint8_t* rv_program = (uint8_t*) malloc(phdr->p_filesz);
    // Go to the segment data and read
    fseek(fd, phdr->p_offset, SEEK_SET);
    fread((void *) rv_program, sizeof(uint8_t), phdr->p_filesz, fd);

    return rv_program;
}

#endif // RV_ELF_H