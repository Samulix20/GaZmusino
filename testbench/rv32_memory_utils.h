#ifndef RV32_MEMORY_UTILS
#define RV32_MEMORY_UTILS

#include <iostream>
#include <format>

#include "rv32_test_utils.h"
#include "rv32_mmio_profiler.h"

// Bsp defines config
#include <ostream>
#include <riscv/config.h>

namespace rv32_test {

inline rv32_memory load_elf(const std::string filename) {
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
    rv32_memory rvmem;
    rvmem.memory = std::unique_ptr<uint8_t>(new uint8_t[phdr->p_memsz]);
    rvmem.max_addr = phdr->p_memsz;

    // Go to the segment data and read
    f.seekg(phdr->p_offset);
    // Copy only the data present in the ELF file
    f.read(
        reinterpret_cast<char*>(rvmem.memory.get()),
        phdr->p_filesz);
    f.close();

    return rvmem;
}

inline void set_memory_banks(Vrv32_top* rvtop, const rv32_memory& rvmem) {
    // Remove unused parameters warnings
    (void) rvtop; (void) rvmem;

    #ifndef CPP_MEMORY_SIM
    
    assert(rvtop->rv32_top->memory->NUM_WORDS >= (rvmem.max_addr >> 2));

    uint8_t* memory = rvmem.memory.get();
    uint8_t bsel = 0;

    for(uint32_t i = 0; i < rvmem.max_addr; i++) {
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

    #endif
}

inline uint32_t read_aligned_word(const rv32_memory& rvmem, const uint32_t addr) {
    return *reinterpret_cast<uint32_t*>(rvmem.memory.get() + (addr & (~3)));
}

template <typename T>
void write_mem(rv32_memory& rvmem, const uint32_t addr, const uint32_t data) {
    *reinterpret_cast<T*>(rvmem.memory.get() + addr) = static_cast<T>(data);
}

inline void mmio_exit_request(SimulationData& sim_data) {
    MemoryRequest request = get_memory_request(sim_data.dut);
    if (request.addr == EXIT_STATUS_ADDR) {
        sim_data.dut->mmio_request_done[0] = 1;

        if (request.op == RV32Types::MEM_SW && sim_data.dut->clk == 1) {
            simulation_exit(sim_data, request.data);
        }
    }
}

inline void mmio_print_request(Vrv32_top* rvtop, std::ostream& fout) {
    MemoryRequest request = get_memory_request(rvtop);
    if (request.addr == PRINT_REG_ADDR) {
        rvtop->mmio_request_done[0] = 1;
        if (request.op == RV32Types::MEM_SW && rvtop->clk == 1) {
            fout << static_cast<char>(request.data);
        }
    }
}

inline void handle_mmio_request(SimulationData& sim_data) {
    sim_data.dut->mmio_request_done[0] = 0;
    mmio_exit_request(sim_data);
    mmio_print_request(sim_data.dut, *sim_data.stdout_file_ptr);
    mmio_profiler_request(sim_data.dut);
}

// Store the values for 1 cycle delay serve
static uint32_t read_instr = 0, read_mem_data = 0;
static uint32_t instr_wait_cyles = 0, data_wait_cyles = 0;
static bool aux = false;

inline void handle_instruction_request(Vrv32_top* rvtop, rv32_memory& rvmem) {

    // Set up values with 1 cycle delay
    rvtop->rv32_top->instr = read_instr;

    // Get request from system bus
    MemoryRequest request = get_instruction_request(rvtop);

    // By default no request is served
    rvtop->rv32_top->instr_request_done = 0;

    // Ignore NOP operations
    if (request.op == RV32Types::MEM_NOP) return;

    if (request.addr <= rvmem.max_addr) {

        rvtop->rv32_top->instr_request_done = 1;

        // Read instruction
        if (rvtop->clk == 1 && request.op == RV32Types::MEM_LW) {
            read_instr = read_aligned_word(rvmem, request.addr);
        }
    } else {
        // Out of memory bounds request
        std::cout << "Out of bounds instruction address request ";
        std::cout << std::format("{:<#10x}", request.addr) << '\n';
        exit(255);
    }
}

inline void handle_data_request(Vrv32_top* rvtop, rv32_memory& rvmem) {
    
    // Set up values with 1 cycle delay
    rvtop->rv32_top->memory_data = read_mem_data;

    // Get request from system bus
    MemoryRequest request = get_memory_request(rvtop);

    // By default no request is served
    rvtop->rv32_top->mem_data_ready = 0;

    // Ignore NOP operations
    if (request.op == RV32Types::MEM_NOP) return;

    if (request.addr <= rvmem.max_addr) {

        // Delay control
        /*
        if (data_wait_cyles >= 1) {
            if (rvtop->clk == 1) data_wait_cyles = 0;
        } else {
            if (rvtop->clk == 1) data_wait_cyles++;
            return;
        }
        */

        rvtop->rv32_top->mem_data_ready = 1;

        // Read/Write data memory
        if (rvtop->clk == 1) {

            read_mem_data = read_aligned_word(rvmem, request.addr);

            switch(request.op) {
                case RV32Types::MEM_SB:
                    write_mem<uint8_t>(rvmem, request.addr, request.data);
                    break;
                case RV32Types::MEM_SH:
                    write_mem<uint16_t>(rvmem, request.addr, request.data);
                    break;
                case RV32Types::MEM_SW:
                    write_mem<uint32_t>(rvmem, request.addr, request.data);
                    break;
                default:
                    break;
            }
        }
    }
}

inline void handle_memory_request(SimulationData& sim_data) {

    handle_mmio_request(sim_data);

    #ifdef CPP_MEMORY_SIM

    handle_instruction_request(sim_data.dut, sim_data.mem);
    handle_data_request(sim_data.dut, sim_data.mem);

    #endif
}

}

#endif
