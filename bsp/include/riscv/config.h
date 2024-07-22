#ifndef RV_CONFIG_H
#define RV_CONFIG_H

#define MEM_SIZE 1024k
#define STACK_SIZE 10240

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
#define PROFILER_COUNTER_START *((volatile uint8_t *) PROFILER_BASE_ADDR)
#define PROFILER_COUNTER_STOP *((volatile uint8_t *) (PROFILER_BASE_ADDR + 1))

#endif
