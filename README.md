# RISC-V System Verilog

## Requirements

- Python 3.x
- Make
- GCC STD c++20
- Verilator 5.024 2024-04-05
- GTKWave
- RISC-V gcc toolchain

### RISC-V Compiler Configure Flags

./configure --enable-multilib --with-multilib-generator="rv32i_zmmul_zicsr-ilp32--"

## Test

RISC-V ISA Test https://github.com/riscv-software-src/riscv-tests
Bringup-bench https://github.com/toddmaustin/bringup-bench
Check https://github.com/eembc/coremark


## References
1. Verilator Tutorial https://itsembedded.com/dhd/verilator_1/
