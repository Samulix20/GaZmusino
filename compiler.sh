#!/bin/bash

# Script for compiling a set of C source files using the required
# Makefiles and BSP for the RISC-V platform

SCRIPT_PWD=$(realpath $(dirname $0))
BSP_DIR=$SCRIPT_PWD/bsp
BUILD_DIR=$(pwd)/build
EXTRA_FLAGS=""

while getopts ":b:f:h" opt; do
  case ${opt} in
    b)
        BUILD_DIR=$OPTARG
        ;;
    f)
        EXTRA_FLAGS=$OPTARG
        ;;
    h)
        echo "Usage $0 -b \"build_directory\" -f \"extra_flags\""
        echo ""
        exit 0
        ;;
    :)
        echo "Option -${OPTARG} requires an argument."
        exit 1
        ;;
    ?)
        echo "Invalid option: -${OPTARG}."
        exit 1
        ;;
  esac
done

shift "$((OPTIND-1))"

# Build elf
make -f $BSP_DIR/Makefile\
    SRCS="$@"\
    BUILD_DIR=$BUILD_DIR\
    EXTRA_FLAGS="$EXTRA_FLAGS"
