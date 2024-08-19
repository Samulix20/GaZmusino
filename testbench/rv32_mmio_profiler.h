#ifndef RV32_MMIO_PROFILER
#define RV32_MMIO_PROFILER

#include <iostream>

#include "rv32_test_utils.h"

#include "../bsp/include/riscv/config.h"

namespace rv32_test {

constexpr uint32_t NUM_MMIO_PROFILER_COUNTERS = 255;

uint64_t profiler_counters[NUM_MMIO_PROFILER_COUNTERS];
uint64_t profiler_counters_starts[NUM_MMIO_PROFILER_COUNTERS];

inline void init_profiler_counters() {
    std::memset(profiler_counters, 0, NUM_MMIO_PROFILER_COUNTERS * sizeof(uint64_t));
}

inline void print_profiler_counters() {
    for(size_t i = 0; i < NUM_MMIO_PROFILER_COUNTERS; i++) {
        if (profiler_counters[i] == 0) continue; // Ignore unused counters
        std::cout << "Counter " << i << " " << profiler_counters[i] << '\n';
    }
}

inline void mmio_profiler_request(Vrv32_top* rvtop, uint64_t sim_time) {
    MemoryRequest request = get_memory_request(rvtop);
    // Start
    if (request.addr == PROFILER_BASE_ADDR) {
        rvtop->mmio_request_done[0] = 1; // Tell the core the request is done
        if (rvtop->clk == 1 && request.op == RV32Types::MEM_SB) {
            uint8_t counter_id = static_cast<uint8_t>(request.data);
            profiler_counters_starts[counter_id] = sim_time;
        }
        
    }
    // Stop
    if (request.addr == (PROFILER_BASE_ADDR + 1)) {
        rvtop->mmio_request_done[0] = 1; // Tell the core the request is done
        if (rvtop->clk == 1 && request.op == RV32Types::MEM_SB) {
            uint8_t counter_id = static_cast<uint8_t>(request.data);
            profiler_counters[counter_id] += (sim_time - profiler_counters_starts[counter_id]) / 2;
        }
    }
}

}

#endif