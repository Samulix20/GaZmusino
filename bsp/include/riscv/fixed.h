#include "types.h"

// Implemented as macros to be more generic

#define MULFIX(a, b, scale) \
    ((int32) (((int64) ((a) * (b))) >> (scale)))

#define DIVFIX(a, b, scale) \
    ((int32) ((((int64) (a)) << (scale)) / (b)))

int32 log2fix(int32 x, const uint8 scale);
int32 logfix(int32 x, const uint8 scale);
