#ifndef RV32_TEST_UTILS
#define RV32_TEST_UTILS

#include <cstdint>
#include <elf.h>
#include <cassert>
#include <fstream>
#include <iostream>

// Device under test headers
#include "Vrv32_top.h"
#include "Vrv32_top_rv32_top.h"
#include "Vrv32_top_rv32_core.h"
#include "Vrv32_top_rv32_decode_stage.h"
#include "Vrv32_top_rv32_exec_stage.h"
#include "Vrv32_top_rv32_mem_stage.h"
#include "Vrv32_top___024unit.h"
#include "Vrv32_top_rv32_main_memory.h"
#include "Vrv32_top_bram__N40000.h"

namespace rv32_test {

// Utilty using statements
using DecodeStageData = Vrv32_top_decode_exec_buffer_t__struct__0;
using ExecutionStageData = Vrv32_top_exec_mem_buffer_t__struct__0;
using MemoryStageData = Vrv32_top_exec_mem_buffer_t__struct__0;
using WritebackStageData = MemoryStageData;
using MemoryRequest = Vrv32_top_memory_request_t__struct__0;

using Instruction = Vrv32_top_rv_instr_t__struct__0;
using DecodedInstruction = Vrv32_top_decoded_instr_t__struct__0;
using RV32Core = Vrv32_top___024unit;

// Getters core internal data
inline DecodeStageData get_decode_stage_data(const Vrv32_top* rvtop) {
    DecodeStageData d;
    d.set(rvtop->rv32_top->core->decode_stage->internal_data);
    return d;
}

inline ExecutionStageData get_exec_stage_data(const Vrv32_top* rvtop) {
    ExecutionStageData d;
    d.set(rvtop->rv32_top->core->exec_stage->internal_data);
    return d;
}

inline MemoryStageData get_mem_stage_data(const Vrv32_top* rvtop) {
    MemoryStageData d;
    d.set(rvtop->rv32_top->core->mem_stage->internal_data);
    return d;
}

inline WritebackStageData get_wb_stage_data(const Vrv32_top* rvtop) {
    WritebackStageData d;
    d.set(rvtop->rv32_top->core->mem_wb_buff);
    return d;
}

inline uint32_t get_next_pc(const Vrv32_top* rvtop) {
    return rvtop->rv32_top->core->next_pc;
}

inline MemoryRequest get_instruction_request(const Vrv32_top* rvtop) {
    MemoryRequest instruction_request;
    instruction_request.set(rvtop->rv32_top->core_instr_request);
    return instruction_request;
}

inline uint32_t get_instruction_response(const Vrv32_top* rvtop) {
    return rvtop->rv32_top->instr;
}

inline MemoryRequest get_memory_request(const Vrv32_top* rvtop) {
    MemoryRequest request;
    request.set(rvtop->mmio_data_request);
    return request;
}

inline uint32_t get_memory_response(const Vrv32_top* rvtop) {
    return rvtop->rv32_top->core_data;
}

inline uint8_t get_memory_stall(const Vrv32_top* rvtop) {
    return rvtop->rv32_top->core->mem_stall;
}

inline uint8_t get_decode_stall(const Vrv32_top* rvtop) {
    return rvtop->rv32_top->core->dec_stall;
}

inline uint8_t get_exec_jump(const Vrv32_top* rvtop) {
    return rvtop->rv32_top->core->exec_jump;
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

    void set_main_memory(Vrv32_top* rvtop) {
        assert(rvtop->rv32_top->memory->NUM_WORDS >= (max_addr >> 2));

        uint8_t bsel = 0;
        for(uint32_t i = 0; i < max_addr; i++) {
            switch (bsel) {
                case 0: 
                    rvtop->rv32_top->memory->b0->ram[i >> 2] = memory[i];
                    break;
                case 1:
                    rvtop->rv32_top->memory->b1->ram[i >> 2] = memory[i];
                    break;
                case 2:
                    rvtop->rv32_top->memory->b2->ram[i >> 2] = memory[i];
                    break;
                case 3:
                    rvtop->rv32_top->memory->b3->ram[i >> 2] = memory[i];
                    break;
                default: break;
            }
            bsel = (bsel + 1) % 4;
        }
    }

    void handle_request(Vrv32_top* rvtop) {
        MemoryRequest request = get_memory_request(rvtop);

        rvtop->mmio_request_done[0] = 0;
        rvtop->mmio_request_done[1] = 0;

        // Check request
        if (request.op == RV32Core::MEM_NOP) return;
        if (!rvtop->clk) return;
        
        // MMIO 0 Exit
        if (request.addr == EXIT_STATUS_ADDR) {
            rvtop->mmio_request_done[0] = 1;
            if (request.op == RV32Core::MEM_SW) {
                std::cout << "Exit status " << request.data << '\n';
                exit(request.data);
            }
        }
        // MMIO 1 Print
        if (request.addr == PRINT_REG_ADDR) {
            rvtop->mmio_request_done[1] = 1;
            if (request.op == RV32Core::MEM_SW) {
                std::cout << static_cast<char>(request.data);
            }
        }
    }
};

}

#endif
