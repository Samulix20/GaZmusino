#ifndef RV_CONFIG_H
#define RV_CONFIG_H

#define MEM_SIZE 1024k
#define STACK_SIZE 10240

#define MTIMER_BASE_ADDR 0x10500000

// mtimer registers
#define MTIMER_COUNTER      *((volatile uint64 *) MTIMER_BASE_ADDR)
#define MTIMER_CMP          *((volatile uint64 *) (MTIMER_BASE_ADDR + 8))

#define PRINT_REG_ADDR 0x10400000

// print register
#define PRINT_REG       *((volatile unsigned int *) PRINT_REG_ADDR)

// Exit/Reset status MMIO
#define EXIT_STATUS_ADDR 0x10600000

#define EXIT_STATUS_REG *((volatile unsigned int *) EXIT_STATUS_ADDR)

#endif
