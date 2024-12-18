#include <stdio.h>

int fxmadd(int a, int b, int c) {
    int x;
    asm (
        ".insn r4 CUSTOM_0, 0, 0, %[x], %[a], %[b], %[c]\n"
        : [x] "=r" (x)
        : [a] "r" (a), [b] "r" (b), [c] "r" (c)
        :
    );
    return x;
}

int main() {
    printf("%i\n", fxmadd(2, 4, 1));
}
