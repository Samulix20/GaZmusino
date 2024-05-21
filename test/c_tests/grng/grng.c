#include <stdlib.h>

#include <riscv/types.h>
#include <riscv/custom.h>

#include "test_vector.h"

int main() {
    for (int i = 0; i < TEST_SIZE; i++) {
        int32 sample = gen_num();
        if(TEST_VECTOR[i] != sample) {
            exit(1);
        }
    }
    return 0;
}
