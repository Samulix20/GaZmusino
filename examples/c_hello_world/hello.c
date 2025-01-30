#include "riscv/mtimer.h"
#include <stdio.h>

int main() {
    enable_mtimer();
    printf("C Hello world!\n");
    return 0;
}
