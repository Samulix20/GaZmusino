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
LIB_INCLUDE="-I $1/lib"

shift 1
if [ "$1" == "-t" ]; then
    EXTRA_ARGS="-t -d build/sim/main.dump.csv"
fi

# Remove previous built simulation elf
rm -rf build/sim

# Compile source files + bsp and store results in build/sim
bash compiler.sh -b build/sim -f "$LIB_INCLUDE" $SRCS

# Build CPU using verilator
make

# Run simulation
echo ""
./obj_dir/Vrv32_top -e build/sim/main.elf $EXTRA_ARGS
