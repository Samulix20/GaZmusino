#include "riscv/profiler/external.h"
#include <stdio.h>

#include <riscv/profiler/internal.h>

inline void exec_nops(const uint8 n) {
    for (uint8 i = 0; i < n; i++) {
        asm volatile("nop");
    }
}

// Function as a macro to avoid optimizations
#define PROFILER_TEST(i, nops)\
    reset_internal_counter(0);\
    start_internal_counter(0);\
    exec_nops((nops));\
    stop_internal_counter(0);\
    cycles = get_internal_counter(0);\
    if (cycles != (nops)) return (i);


int main() {
    uint64 cycles;

    // A few test, nop number is small so the function get inlined
    PROFILER_TEST(1, 5);
    PROFILER_TEST(2, 6);
    PROFILER_TEST(3, 7);
    PROFILER_TEST(4, 2);
    PROFILER_TEST(5, 3);

    return 0;
}
