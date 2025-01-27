# GaZmusino. A tiny open source RISC-V processor

This project is an open-source implementation of a `rv32i_zmmul_zicsr` RISC-V processor, designed for learning and experimentation developed in the GaZ research group.

## Features

- RISC-V ISA Compliance: Supports the `rv32i_zmmul_zicsr` instruction set.
- Modular Design: Easily extendable with additional functional units.
- Memory Options: Includes a C++ simulated RAM or a SystemVerilog-based implementation.
- Instruction Simulation: Enables C++ testbench-based instruction simulation.
- Flexible Build Tools: Python-based build module simplifies running ASM/C/C++ projects on the processor.
- Trace Visualization: Compatible with [Konata](https://github.com/shioyadan/Konata) for visualizing execution traces.
- Basic BSP Implementation: Provides a basic board support package (BSP) for static linking with libc.
- Automated Testing: Includes a suite of adapted [RISC-V standard isa tests](https://github.com/riscv-software-src/riscv-tests) and the [bringup-bench](https://github.com/toddmaustin/bringup-bench) test collection.
- FPGA Compatibility: Synthesizable for deployment on Xilinx FPGAs. Tested on Zynq UltraScale+ ZCU104 Evaluation Board FPGA with a target clock frequency of 100 Mhz.

## Cloning

The bringup-bench test collection is included as a submodule. To clone this repository, use:

```bash
git clone --recurse-submodules
```

## Requirements
The following program versions have been verified to work. Other versions may not work as expected:

- Python 3.12.7
- Make 4.4.1
- GCC x86_64 14.2.1
- RISC-V GNU toolchain 13.2.0
- Verilator 5.024 2024-04-05

### RISC-V GNU toolchain flags

The RISC-V GNU toolchain must be configured using the following flags:

```bash
./configure --enable-multilib --with-multilib-generator="rv32i_zmmul_zicsr-ilp32--"
```

## Testing

To execute a basic set of tests and build the processor using Verilator, run:

```bash
make test
```

For a larger set of tests, run:

```bash
make bringup
```

## Examples

The `examples` directory includes two "Hello World!" projects. These can be executed using the Python `build.py` module:
```python
import build
# C++ Hello world project 
build.build_and_run("examples/cpp_hello_world", "build")
# C Hello world project
build.build_and_run("examples/c_hello_world", "build")
```

Both projects include `libc` startup code. For a baremetal project, use:
```python
import build
build.build_and_run_bare("examples/bare", "build", "trace.trace", "trace.kanata")
```

Simulation outputs can include the stdout file, a YAML file containing profiling counters values, and a trace file that can be visualized using Konata.
```python
import build
build_and_run_log("examples/c_hello_world", "build", "stdout.txt", "prof.yaml")
```
