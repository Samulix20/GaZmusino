#include "axi_serial.h"

void axi_serial_init() {
    AXI_SERIAL_REG = 0;
}

void axi_serial_send_char(const uint8_t c) {
    // Busy wait
    // RDY 1 data pending for read
    while(((AXI_SERIAL_REG >> 8) & 1) == 1);
    // Set data with RDY flag
    AXI_SERIAL_REG = (1 << 8) | (0xff & c);
}

uint8_t axi_serial_recv_char() {
    uint8_t c = 0;
    // Busy wait
    // RDY 0 not data available
    uint32_t tmpreg = AXI_SERIAL_REG;
    while(((tmpreg >> 8) & 1) == 0) tmpreg = AXI_SERIAL_REG;
    c = tmpreg & 0xff;
    // Set RDY to 0
    AXI_SERIAL_REG = 0;
    return c;
}
