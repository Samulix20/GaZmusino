#include <stdint.h>

#include "test_vec.h"

// Rust types

typedef int32 i32;
typedef uint32 u32;
typedef int8 i8;
typedef uint8 u8;

#define DEFAULT_SEED 0xDEADBEEF
uint32 seed = DEFAULT_SEED;

// https://en.wikipedia.org/wiki/Xorshift
inline uint32 xorshift32(uint32 seed) {
    uint32 x = seed;
	x ^= x << 13;
	x ^= x >> 17;
	x ^= x << 5;
	return x;
}

// Deprecated
// Bernoulli sample scaled at S
inline i32 bernoulli_sample(u8 S, i32 q, i32 p) {
    extern uint32 seed;
    // seed S = 32
    seed = xorshift32(seed);
    i32 scaled_sample =  (i32) (seed >> (32 - S));
    if (p > scaled_sample) return (i32) q;
    else return 0;
}

// Uniform sample scaled at S
inline i32 uniform_sample(u8 S) {
    extern uint32 seed;
    // Seed can be iterpreted as scaled at S = 32
    seed = xorshift32(seed);
    return (i32) (seed >> (32 - S));
}

// Normal sample scaled at S using clt approximation
inline i32 clt_normal_sample(u8 S) {
    // Scaled at S
    i32 acc = 0;
    for(size_t i = 0; i < 12; i++) {
        acc += uniform_sample(S);
    }
    // Center value
    acc -= (6 << S); // Scale 6 to S
    return acc;
}


inline i32 fxmadd(i32 a, i32 b, i32 c, u8 s_id) {
    i32 x;
    asm volatile(
        ".insn r4 CUSTOM_1, %4, 0, %0, %1, %2, %3"
        : "=r"(x)
        : "r"(a), "r"(b), "r"(c), "i"(s_id)
    );
    return x;
}

inline i32 genum_fxmadd(i32 x, i32 a, i32 b, i32 c, u8 s_id) {
    asm volatile(
        ".insn r CUSTOM_0, 0, 0, t6, x0, x0\n"
        ".insn r4 CUSTOM_1, %[s_id], 0, t6, %[a], t6, %[b]\n"
        ".insn r4 CUSTOM_1, %[s_id], 0, %[x], t6, %[c], %[x]\n"
        : [x] "+r"(x)
        : [a] "r"(a), [b] "r"(b), [c] "r"(c), [s_id] "i"(s_id)
        : "t6"
    );
    return x;
}


inline i32 g_uniform() {
    return uniform_sample(12);
}

inline i32 g_normal() {
    return clt_normal_sample(12);
}

inline i32 g_instr() {
    i32 x;
    asm volatile (
        ".insn r CUSTOM_0, 0, 0, %0, x0, x0"
        : "=r" (x)
    );
    return x;
}

inline i32 g() {
    //return g_normal();
    //return g_uniform();
    return g_instr();
}

inline i32 f_no_instr(i32 x, i32 a, i32 b, i32 c, u8 s) {
    i32 m = 0;
    i32 u = g(); 
    m = ((u * a) >> s) + b;
    x = ((m * c) >> s) + x;
    return x;
}

inline i32 f_instr(i32 x, i32 a, i32 b, i32 c, u8 s) {
    i32 m = 0;
    i32 u = g(); 
    m = fxmadd(u, a, b, s);
    x = fxmadd(m, c, x, s);
    return x;
}

inline i32 f_instr_reoder(i32 x, i32 a, i32 b, i32 c, u8 s) {
    return genum_fxmadd(x, a, b, c, s);
}

int main() {
    i32 x;

    start_external_counter(0);
    x = 0;
    for(i32 i = 0; i < TEST_SIZE; i++) {
        i32 a = vec_a[i], b = vec_b[i], c = vec_c[i];
        x = f_no_instr(x, a, b, c, 2);
    }
    vec_res[0] = x;
    stop_external_counter(0);

    start_external_counter(1);
    x = 0;
    for(i32 i = 0; i < TEST_SIZE; i++) {
        i32 a = vec_a[i], b = vec_b[i], c = vec_c[i];
        x = f_instr(x, a, b, c, 2);
    }
    vec_res[1] = x;
    stop_external_counter(1);

    start_external_counter(2);
    x = 0;
    for(i32 i = 0; i < TEST_SIZE; i++) {
        i32 a = vec_a[i], b = vec_b[i], c = vec_c[i];
        x = f_instr_reoder(x, a, b, c, 2);
    }
    vec_res[2] = x;
    stop_external_counter(2);

    return 0;
}
