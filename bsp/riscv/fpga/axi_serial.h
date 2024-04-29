#ifndef RV_FPGA_AXI_SERIAL_H
#define RV_FPGA_AXI_SERIAL_H

// AXI 1 register comunication

#include <stdint.h>

#define AXI_SERIAL_REG_ADDR   0x10700000

// bit 8 RDY bits 7-0 uint8_t data
#define AXI_SERIAL_REG    *((volatile uint32_t *) AXI_SERIAL_REG_ADDR)

void axi_serial_init();
uint8_t get_axi_serial_rdy();
void axi_serial_send_char(const uint8_t c);
uint8_t axi_serial_recv_char();

#endif
