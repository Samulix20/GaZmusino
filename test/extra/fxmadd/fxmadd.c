#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

typedef int32_t i32;
typedef uint32_t u32;
typedef int8_t i8;
typedef uint8_t u8;

// https://en.wikipedia.org/wiki/Xorshift
u32 xorshift32(u32 seed) {
    u32 x = seed;
	x ^= x << 13;
	x ^= x >> 17;
	x ^= x << 5;
	return x;
}

inline int fxmadd(i32 a, i32 b, i32 c, u8 inm) {
    int x;
    const u8 inm_low_bits = inm & 0b111 ;
    const u8 inm_high_bits = (inm >> 3) & 0b11;
    asm volatile(
        ".insn r4 CUSTOM_0, %4, %5, %0, %1, %2, %3\n"
        : "=r" (x)
        : "r" (a), "r" (b), "r" (c), "i" (inm_low_bits), "i" (inm_high_bits)
    );
    return x;
}

int fxmadd_local(i32 a, i32 b, i32 c, u8 inm){
    uint64_t mult = a * b;
    uint64_t mult_shifted = mult >> inm;
    return mult_shifted + c;
}

static inline __attribute__((always_inline)) u8 test_fxmadd(const u8 inm) {
    i32 a = 1, b = 2, c = 3;
    for (int i = 0; i < 1000; i++) {
        a = xorshift32(a);
        b = xorshift32(a);
        c = xorshift32(b);
        if (fxmadd(a, b, c, inm) != fxmadd_local(a, b, c, inm)) {
            return 0;
        }
    }
    return 1;
}

int main() {
    if(test_fxmadd(4)) {
        printf("Test passed\n");
    } else {
        printf("Test failed\n");
    }
    if(test_fxmadd(8)) {
        printf("Test passed\n");
    } else {
        printf("Test failed\n");
    }
}
