#include <stdio.h>
#include <stdint.h>

inline int32_t fxmadd(int32_t a, int32_t b, int32_t c, uint8_t s_id) {
    int32_t x;
    asm volatile(
        ".insn r4 CUSTOM_1, %4, 0, %0, %1, %2, %3"
        : "=r"(x)
        : "r"(a), "r"(b), "r"(c), "i"(s_id)
    );
    return x;
}

int main() {
    int32_t x = fxmadd(1, 2, 3, 1);
    printf("%li\n", x);
}

