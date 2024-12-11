#ifndef RV_TARGET_H
#define RV_TARGET_H

#define MEM_SIZE 20480k
#define STACK_SIZE 1000k
#define HEAP_SIZE 1000k

// Profiler internal counters
#define NUM_PROFILER_COUNTERS 8

// mtimer MMIO 
#define MTIMER_BASE_ADDR 0x10500000
#define MTIMER_COUNTER      *((volatile uint64_t *) MTIMER_BASE_ADDR)
#define MTIMER_CMP          *((volatile uint64_t *) (MTIMER_BASE_ADDR + 8))

// Serial print register MMIO 
#define PRINT_REG_ADDR 0x10400000
#define PRINT_REG       *((volatile uint32_t *) PRINT_REG_ADDR)

// Exit/Reset status MMIO
#define EXIT_STATUS_ADDR 0x10600000
#define EXIT_STATUS_REG *((volatile uint32_t *) EXIT_STATUS_ADDR)

// Profiler counter MMIO
#define PROFILER_BASE_ADDR 0x10700000
#define PROFILER_COUNTER_START *((volatile uint32_t *) PROFILER_BASE_ADDR)
#define PROFILER_STOP_ADDR (PROFILER_BASE_ADDR + 4)
#define PROFILER_COUNTER_STOP *((volatile uint32_t *) PROFILER_STOP_ADDR)

#endif
