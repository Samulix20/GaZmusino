#ifndef RV32_TEST_UTILS
#define RV32_TEST_UTILS

#include <elf.h>
#include <cassert>
#include <fstream>
#include <iostream>

// Device under test headers
#include "Vrv32_core.h"
#include "Vrv32_core_rv32_core.h"
#include "Vrv32_core_rv32_decode_stage.h"
#include "Vrv32_core_rv32_exec_stage.h"
#include "Vrv32_core_rv32_mem_stage.h"
#include "Vrv32_core___024unit.h"

namespace rv32_test {

// Utilty using statements
using DecodeStageData = Vrv32_core_decode_exec_buffer_t__struct__0;
using ExecutionStageData = Vrv32_core_exec_mem_buffer_t__struct__0;
using MemoryStageData = Vrv32_core_mem_wb_buffer_t__struct__0;
using WritebackStageData = MemoryStageData;
using MemoryRequest = Vrv32_core_memory_request_t__struct__0;
using MemoryResponse = Vrv32_core_memory_response_t__struct__0;

using Instruction = Vrv32_core_rv_instr_t__struct__0;
using DecodedInstruction = Vrv32_core_decoded_instr_t__struct__0;
using RV32Core = Vrv32_core___024unit;

// Getters core internal data
inline DecodeStageData get_decode_stage_data(const Vrv32_core* rvcore) {
    DecodeStageData d;
    d.set(rvcore->rv32_core->decode_stage->internal_data);
    return d;
}

inline ExecutionStageData get_exec_stage_data(const Vrv32_core* rvcore) {
    ExecutionStageData d;
    d.set(rvcore->rv32_core->exec_stage->internal_data);
    return d;
}

inline MemoryStageData get_mem_stage_data(const Vrv32_core* rvcore) {
    MemoryStageData d;
    d.set(rvcore->rv32_core->mem_stage->internal_data);
    return d;
}

inline WritebackStageData get_wb_stage_data(const Vrv32_core* rvcore) {
    WritebackStageData d;
    d.set(rvcore->rv32_core->mem_wb_buff);
    return d;
}

inline uint32_t get_next_pc(const Vrv32_core* rvcore) {
    return rvcore->rv32_core->next_pc;
}

inline MemoryRequest get_instruction_request(const Vrv32_core* rvcore) {
    MemoryRequest instruction_request;
    instruction_request.set(rvcore->instr_request);
    return instruction_request;
}

inline MemoryResponse get_instruction_response(const Vrv32_core* rvcore) {
    MemoryResponse instruction_response;
    instruction_response.set(rvcore->instr_response);
    return instruction_response;
}

inline MemoryRequest get_memory_request(const Vrv32_core* rvcore) {
    MemoryRequest mem_request;
    mem_request.set(rvcore->data_request);
    return mem_request;
}

inline MemoryResponse get_memory_response(const Vrv32_core* rvcore) {
    MemoryResponse mem_response;
    mem_response.set(rvcore->data_response);
    return mem_response;
}

// Bsp defines config
#include "../bsp/riscv/config.h"

class RVMemory {
  private:
    uint8_t* memory = nullptr;
    uint32_t max_addr = 0;

  public:
    // Default constructor
    RVMemory() {}
    
    // load elf constructor
    RVMemory(const std::string filename) {
        load_elf(filename);
    }

    ~RVMemory() {
        // Free if allocated
        if (memory != nullptr) delete memory;
    }

    void load_elf(const std::string filename) {
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
        if (memory != nullptr) delete memory;
        memory = new uint8_t[phdr->p_memsz];
        max_addr = phdr->p_memsz;
        // Go to the segment data and read
        f.seekg(phdr->p_offset);
        // Copy only the data present in the ELF file
        f.read(reinterpret_cast<char*>(memory), phdr->p_filesz);
        f.close();
    }

    static uint32_t read_aligned_word(
        const uint8_t* memory, const uint32_t addr) {

        return *reinterpret_cast<const uint32_t*>(memory + (addr & (~3)));
    }

    template<typename T>
    static void memory_write(
        uint8_t* memory, const uint32_t addr, const uint32_t data) {

        *reinterpret_cast<T*>(memory + addr) = static_cast<T>(data);
    }

    MemoryResponse handle_request(const MemoryRequest request) {
        MemoryResponse response;
        response.data = 0;
        response.ready = 1;

        // Check request
        if (request.op == RV32Core::MEM_NOP) return response;
        
        // MMIO Exit
        if (request.addr == EXIT_STATUS_ADDR) {
            if (request.op == RV32Core::MEM_SW) {
                std::cout << "Exit status " << request.data << '\n';
                exit(request.data);
            }
        }
        // MMIO Print
        if (request.addr == PRINT_REG_ADDR) {
            if (request.op == RV32Core::MEM_SW) {
                std::cout << static_cast<char>(request.data);
                return response;
            }
        }

        // Check addr
        assert(request.addr < max_addr);

        switch(request.op) {
            case RV32Core::MEM_SB:
                memory_write<uint8_t>(memory, request.addr, request.data);
                break;
            case RV32Core::MEM_SH:
                memory_write<uint16_t>(memory, request.addr, request.data);
                break;
            case RV32Core::MEM_SW:
                memory_write<uint32_t>(memory, request.addr, request.data);
                break;
            default:
                response.data = read_aligned_word(memory, request.addr);
                break;
        }

        return response;
    }
};

}

#endif
