
#include "riscv/types.h"
#include <riscv/print.h>
#include <riscv/custom.h>

int main() {
    for (int i = 0; i < 10; i++) {
        int32 aux = gen_num();
        printf("aux = %i\n", aux);
    }
    return 0;
}
