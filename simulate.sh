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
LIB_INCLUDE="-I $1"
TARGET_DIR=$1

shift 1
if [ "$1" == "-t" ]; then
    EXTRA_ARGS="-t -d build/sim/main.dump.csv"
    shift 1
fi

EXTRA_COMP_FLAGS=$1

# Remove previous built simulation elf
rm -rf build/$TARGET_DIR

# Compile source files + bsp and store results in build/sim
bash compiler.sh -b build/$TARGET_DIR -f "$LIB_INCLUDE $EXTRA_COMP_FLAGS" $SRCS

# Build CPU using verilator
make

# Run simulation
echo ""
./obj_dir/Vrv32_top -e build/$TARGET_DIR/main.elf $EXTRA_ARGS
