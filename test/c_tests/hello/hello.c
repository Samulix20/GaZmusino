#include <stdio.h>
#include <riscv/profiler/external.h>

int main() {
    start_external_counter(0);
    start_external_counter(1);
    printf("Hello world!\n");
    stop_external_counter(0);
    stop_external_counter(1);
    return 0;
}
