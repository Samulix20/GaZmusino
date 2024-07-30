#ifndef PROFILER_INTERNAL_H
#define PROFILER_INTERNAL_H

#include <riscv/types.h>

// Cost 2 cycles (Overhead)
inline void set_mcountinhibit() {
    asm volatile(
        "li x31, 1\n"
        "csrs mcountinhibit, x31"
        ::: "x31"
    );
}

#endif