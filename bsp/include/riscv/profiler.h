#ifndef PROFILER_H
#define PROFILER_H

#include "riscv/types.h"
#include <riscv/config.h>

inline void start_counter(const uint8 id) {
    PROFILER_COUNTER_START = id;
}

inline void stop_counter(const uint8 id) {
    PROFILER_COUNTER_STOP = id;
}

#endif