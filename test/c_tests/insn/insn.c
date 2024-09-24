#include <stdio.h>

int main() {

    unsigned int x = 444;

    asm volatile(
        "li a1, 1\n"
        "li a2, 2\n"
        "li a3, 3\n"
        ".insn r4 CUSTOM_1, 1, 0, %0, a1, a2, a3"
        : "=r" (x)
    );

    printf("%i\n", x);

    return 0;
}

