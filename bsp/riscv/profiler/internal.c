#include <riscv/profiler/internal.h>
#include <riscv/csr.h>

uint64 counters[NUM_PROFILER_COUNTERS] = {
    0
};
uint64 counters_starts[NUM_PROFILER_COUNTERS] = {
    0
};
uint32 times_started[NUM_PROFILER_COUNTERS] = {
    0
};

void _start_internal_counter(const uint8 id) {
    // Error counter does not exist
    if (id >= NUM_PROFILER_COUNTERS) return;

    counters_starts[id] = read_mcycle();
}

void _stop_internal_counter(const uint8 id) {
    // Error counter does not exist
    if (id >= NUM_PROFILER_COUNTERS) return;

    // Only required at stop because those are counted after the start
    // -2 overhead cycles of disabling the hw counter
    counters[id] += read_mcycle() - 2 - counters_starts[id];
}

uint64 get_internal_counter(const uint8 id) {
    // Error counter does not exist
    if (id >= NUM_PROFILER_COUNTERS) return 0;

    return counters[id];
}

void reset_internal_counter(const uint8 id) {
    // Error counter does not exist
    if (id >= NUM_PROFILER_COUNTERS) return;

    counters[id] = 0;
}
