#include <stdio.h>

#include <riscv/profiler/internal.h>

int main() {
    set_mcountinhibit();
    printf("Hello world!\n");
    fflush(stdout);
    return 0;
}
