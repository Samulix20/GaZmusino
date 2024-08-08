#ifndef RV32_TEST_UTILS
#define RV32_TEST_UTILS

#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <elf.h>
#include <cassert>
#include <fstream>
#include <iostream>
#include <memory>
#include <sstream>
#include <string.h>
#include <string>

// Device under test headers
#include "Vrv32_top_rv32_types.h"

#include "Vrv32_top.h"
#include "Vrv32_top_rv32_top.h"
#include "Vrv32_top_rv32_core.h"
#include "Vrv32_top_rv32_decode_stage.h"
#include "Vrv32_top_rv32_exec_stage.h"
#include "Vrv32_top_rv32_mem_stage.h"

/*
#include "Vrv32_top_rv32_main_memory.h"
#include "Vrv32_top_bram_2_port__N100000.h"
*/

namespace rv32_test {

// Utilty using statements
using DecodeStageData = Vrv32_top_decode_exec_buffer_t__struct__0;
using ExecutionStageData = Vrv32_top_exec_mem_buffer_t__struct__0;
using MemoryStageData = Vrv32_top_exec_mem_buffer_t__struct__0;
using WritebackStageData = MemoryStageData;
using MemoryRequest = Vrv32_top_memory_request_t__struct__0;

using Instruction = Vrv32_top_rv_instr_t__struct__0;
using DecodedInstruction = Vrv32_top_decoded_instr_t__struct__0;
using RV32Types = Vrv32_top_rv32_types;

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

inline uint32_t get_wb_result_data(const Vrv32_top* rvtop) {
    return rvtop->rv32_top->core->wb_data;
}

inline uint32_t get_next_pc(const Vrv32_top* rvtop) {
    return rvtop->rv32_top->core->next_pc;
}

inline MemoryRequest get_instruction_request(const Vrv32_top* rvtop) {
    MemoryRequest instruction_request;
    instruction_request.set(rvtop->core_instr_request);
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

struct rv32_elf_program {
    uint32_t max_addr;
    std::unique_ptr<uint8_t> memory;
};

inline rv32_elf_program load_elf(const std::string filename) {
    std::ifstream f(filename, std::ios::binary);
    // Check file is open
    assert(f.is_open());

    // Read header
    std::unique_ptr<Elf32_Ehdr> ehdr(new Elf32_Ehdr);
    f.read(reinterpret_cast<char*>(ehdr.get()), sizeof(*ehdr));

    // Check is a 32 bit elf file
    assert(ehdr->e_ident[EI_CLASS] == 1);
    // Check is for RISC-V
    assert(ehdr->e_machine == EM_RISCV);

    // Set fd to read program header
    // Seek and read segment 1 cause segment 0 is used for RV attributes
    std::unique_ptr<Elf32_Phdr> phdr(new Elf32_Phdr);
    f.seekg(ehdr->e_phoff + sizeof(*phdr));
    f.read(reinterpret_cast<char*>(phdr.get()), sizeof(*phdr));
    
    // Make sure its loadable
    assert(phdr->p_type == PT_LOAD);

    // Allocate memory of size in memory
    rv32_elf_program elf_program;
    elf_program.memory = std::unique_ptr<uint8_t>(new uint8_t[phdr->p_memsz]);
    elf_program.max_addr = phdr->p_memsz;

    // Go to the segment data and read
    f.seekg(phdr->p_offset);
    // Copy only the data present in the ELF file
    f.read(
        reinterpret_cast<char*>(elf_program.memory.get()),
        phdr->p_filesz);
    f.close();

    return elf_program;
}

uint32_t read_aligned_word(const rv32_elf_program& elf_program, const uint32_t addr) {
    return *reinterpret_cast<uint32_t*>(elf_program.memory.get() + (addr & (~3)));
}

template <typename T>
void write_mem(rv32_elf_program& elf_program, const uint32_t addr, const uint32_t data) {
    *reinterpret_cast<T*>(elf_program.memory.get() + addr) = static_cast<T>(data);
}

uint32_t read_instr = 0, read_mem_data = 0;

inline void handle_main_memory_request_comb(Vrv32_top* rvtop, rv32_elf_program& elf_program) {
    rvtop->rv32_top->instr = read_instr;
    rvtop->rv32_top->memory_data = read_mem_data;

    MemoryRequest mem_request = get_memory_request(rvtop);
    MemoryRequest instr_request = get_instruction_request(rvtop);

    rvtop->rv32_top->instr_request_done = 0;
    rvtop->rv32_top->mem_data_ready = 0;

    if (instr_request.addr <= elf_program.max_addr) {
        rvtop->rv32_top->instr_request_done = 1;

        // FlipFlop
        if (rvtop->clk == 0 && instr_request.op == RV32Types::MEM_LW) {
            read_instr = read_aligned_word(elf_program, instr_request.addr);
        }
    } else {
        // Out of bounds memory request
        // TODO add error msg
        std::cout << "PANIC" << '\n';
        exit(1);
    }

    if (mem_request.addr <= elf_program.max_addr) {
        rvtop->rv32_top->mem_data_ready = 1;
        
        // FlipFlop
        if (rvtop->clk == 0) {

            read_mem_data = read_aligned_word(elf_program, mem_request.addr);

            switch(mem_request.op) {
                case RV32Types::MEM_SB:
                    write_mem<uint8_t>(elf_program, mem_request.addr, mem_request.data);
                    break;
                case RV32Types::MEM_SH:
                    write_mem<uint16_t>(elf_program, mem_request.addr, mem_request.data);
                    break;
                case RV32Types::MEM_SW:
                    write_mem<uint32_t>(elf_program, mem_request.addr, mem_request.data);
                    break;
                default:
                    break;
            }
        }
    }

}

/*
inline void set_banked_memory(Vrv32_top* rvtop, const rv32_elf_program& elf_program) {
    assert(rvtop->rv32_top->memory->NUM_WORDS >= (elf_program.max_addr >> 2));

    uint8_t* memory = elf_program.memory.get();
    uint8_t bsel = 0;

    for(uint32_t i = 0; i < elf_program.max_addr; i++) {
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
*/

// Bsp defines config
#include "../bsp/include/riscv/config.h"

uint64_t profiler_counters[255];
uint64_t profiler_counters_starts[255];

inline void init_profiler_counters() {
    std::memset(profiler_counters, 0, 255 * sizeof(uint64_t));
}

inline void print_profiler_counters() {
    for(size_t i = 0; i < 255; i++) {
        if (profiler_counters[i] == 0) continue; // Ignore unused counters
        std::cout << "Counter " << i << " " << profiler_counters[i] << '\n';
    }
}

inline void handle_mmio_request(Vrv32_top* rvtop, uint64_t sim_time) {
    MemoryRequest request = get_memory_request(rvtop);

    rvtop->mmio_request_done[0] = 0;
    rvtop->mmio_request_done[1] = 0;

    // Check request
    if (request.op == RV32Types::MEM_NOP) return;

    // MMIO 0 Exit
    if (request.addr == EXIT_STATUS_ADDR) {
        rvtop->mmio_request_done[0] = 1;
        if (request.op == RV32Types::MEM_SW && rvtop->clk == 0) {
            std::cout << '\n' << "Exit status " << request.data << '\n';
            std::cout << "Sim time " << sim_time << '\n';
            print_profiler_counters();
            exit(request.data);
        }
    }
    // MMIO 1 Print
    if (request.addr == PRINT_REG_ADDR) {
        rvtop->mmio_request_done[1] = 1;
        if (request.op == RV32Types::MEM_SW && rvtop->clk == 0) {
            std::cout << static_cast<char>(request.data);
        }
    }
    // MMIO Profiler
    // Start
    if (request.addr == PROFILER_BASE_ADDR) {
        rvtop->mmio_request_done[1] = 1; // Tell the core the request is done
        if (request.op == RV32Types::MEM_SB && rvtop->clk == 0) {
            uint8_t counter_id = static_cast<uint8_t>(request.data);
            profiler_counters_starts[counter_id] = sim_time;
        }
        
    }
    // Stop
    if (request.addr == (PROFILER_BASE_ADDR + 1)) {
        rvtop->mmio_request_done[1] = 1; // Tell the core the request is done
        if (request.op == RV32Types::MEM_SB && rvtop->clk == 0) {
            uint8_t counter_id = static_cast<uint8_t>(request.data);
            profiler_counters[counter_id] += (sim_time - profiler_counters_starts[counter_id]) / 2;
        }
    }
}

using DissasemblyMap = std::unordered_map<uint32_t, std::string>;

inline DissasemblyMap load_dissasembly(std::string filename) {
    DissasemblyMap m;
    std::stringstream ss;
    std::string line = "", pc_token = "", instr_token = "";

    std::ifstream f = std::ifstream(filename);
    if (!f.is_open()) return m;

    while(!f.eof()) {
        getline(f, line);
        if (line == "") continue; // Guard for empty lines
        ss.clear();
        ss << line;
        getline(ss, pc_token, ';');
        getline(ss, instr_token, ';');
        m[std::stoi(pc_token)] = instr_token;
    }

    return m;
}

}

#endif
