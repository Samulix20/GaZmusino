#ifndef RV32_MMIO_PROFILER
#define RV32_MMIO_PROFILER

#include <iostream>

#include "rv32_test_utils.h"

#include <riscv/config.h>

namespace rv32_test {

constexpr uint32_t NUM_MMIO_PROFILER_COUNTERS = 255;

struct profiler_counters {
    uint64_t cycles;
    uint64_t instructions;
};

static profiler_counters counters [NUM_MMIO_PROFILER_COUNTERS];
static profiler_counters counters_starts[NUM_MMIO_PROFILER_COUNTERS];

inline void init_profiler_counters() {
    std::memset(counters, 0, NUM_MMIO_PROFILER_COUNTERS * sizeof(profiler_counters));
}

inline void print_profiler_counters() {
    for(size_t i = 0; i < NUM_MMIO_PROFILER_COUNTERS; i++) {
        if (counters[i].cycles == 0) continue; // Ignore unused counters
        std::cout << "Counter " << i << " Cycles " << counters[i].cycles;
        std::cout << " Instructions " << counters[i].instructions << '\n';
    }
}

inline void mmio_profiler_request(Vrv32_top* rvtop) {
    MemoryRequest request = get_memory_request(rvtop);
    // Start
    if (request.addr == PROFILER_BASE_ADDR) {
        rvtop->mmio_request_done[0] = 1; // Tell the core the request is done
        if (rvtop->clk == 1 && request.op == RV32Types::MEM_SW) {
            uint8_t counter_id = static_cast<uint8_t>(request.data);
            
            counters_starts[counter_id].cycles = get_mcycle(rvtop);
            counters_starts[counter_id].instructions = get_minstret(rvtop);
        }
        
    }
    // Stop
    if (request.addr == PROFILER_STOP_ADDR) {
        rvtop->mmio_request_done[0] = 1; // Tell the core the request is done
        if (rvtop->clk == 1 && request.op == RV32Types::MEM_SW) {
            uint8_t counter_id = static_cast<uint8_t>(request.data);
            
            counters[counter_id].cycles += get_mcycle(rvtop) - counters_starts[counter_id].cycles;
            counters[counter_id].instructions += get_minstret(rvtop) - counters_starts[counter_id].instructions;
        }
    }
}

}

#endif