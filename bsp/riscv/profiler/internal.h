#ifndef PROFILER_INTERNAL_H
#define PROFILER_INTERNAL_H

#include <rvtarget.h>
#include <riscv/csr.h>

// Private real functions
void _start_internal_counter(const uint8 id);
void _stop_internal_counter(const uint8 id);

// Wrappers that disable/enable the hw counters

inline void start_internal_counter(const uint8 id) {
    disable_hw_counters();
    _start_internal_counter(id);
    enable_hw_counters();
}

inline void stop_internal_counter(const uint8 id) {
    disable_hw_counters();
    _stop_internal_counter(id);
    enable_hw_counters();
}

uint64 get_internal_counter(const uint8 id);

void reset_internal_counter(const uint8 id);

#endif
