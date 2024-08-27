#ifndef PROFILER_EXTERNAL_H
#define PROFILER_EXTERNAL_H

#include <riscv/types.h>
#include <riscv/config.h>

inline void start_external_counter(const uint32 id) {
    PROFILER_COUNTER_START = id;
}

inline void stop_external_counter(const uint32 id) {
    PROFILER_COUNTER_STOP = id;
}

#endif