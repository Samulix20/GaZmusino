#include <stdlib.h>

#include <riscv/types.h>
#include <riscv/custom.h>

#include "test_vector.h"

int main() {

    // Test default seed
    for (int i = 0; i < TEST_SIZE; i++) {
        int32 sample = gen_num();
        if(TEST_VECTOR[i] != sample) {
            exit(i + 1);
        }
    }

    // Test change seed
    set_seed(NEW_SEED, 0);

    for (int i = 0; i < TEST_SIZE; i++) {
        int32 sample = gen_num();
        if(TEST_VECTOR_SEED_CHANGE[i] != sample) {
            exit(i + 1);
        }
    }

    return 0;
}
