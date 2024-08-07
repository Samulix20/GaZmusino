#!/bin/bash

# Script for compiling a C project folder and run a simulation in
# the RISC-V platform

if [ -z "$1" ]; then
    echo "Usage $0 \"project_directory\""
    echo ""
    exit 1
fi

# Get source files
SRCS="$(find $1 -name '*.c') $(find $1 -name '*.S') $(find $1 -name '*.cpp')"

# Remove previous built simulation elf
rm -rf build/sim

# Compile source files + bsp and store results in build/sim
bash compiler.sh -b build/sim -f "-I $1/libs" $SRCS

# Build CPU using verilator
make

# Run simulation
echo ""
./obj_dir/Vrv32_top -e build/sim/main.elf
