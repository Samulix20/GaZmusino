#pragma once

#include <inttypes.h>
#include <stdio.h>

void print_bits(size_t size, const void* p) {
    const uint8_t* ptr_b = (const uint8_t*) p;

    for(int8_t i = size - 1; i >= 0; i--) {
        for(int8_t j = 7; j >= 0; j--) {
            printf("%u", (ptr_b[i] >> j) & 1);
        }
    }

}
