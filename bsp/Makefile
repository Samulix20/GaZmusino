# Makefile for compilation of C/C++ programs for RISC-V platform
SRCS ?=				# Source file list
BUILD_DIR ?=		# Build directory
EXTRA_FLAGS ?=		# Optional extra flags

.PHONY: all
all: $(BUILD_DIR)/linker.lds $(BUILD_DIR)/main.elf $(BUILD_DIR)/main.dump

# Setup BSP source dir
BSP_DIR := $(shell dirname $(realpath $(MAKEFILE_LIST)))

# Cross Compiler definitions
CROSS := riscv64-unknown-elf-
CC := $(CROSS)gcc
CXX := $(CROSS)g++
DUMP := $(CROSS)objdump

# Compiler flags
OPTFLAGS := \
	-fdata-sections -ffunction-sections -Wl,--gc-sections,-S \
	-Wall -Wextra -O3 \
	-fopt-info-optimized=$(BUILD_DIR)/comp_report.txt
ARCHFLAGS := -march=rv32i_zmmul_zicsr -mabi=ilp32
BSPFLAGS := -I $(BSP_DIR) -T $(BUILD_DIR)/linker.lds

CFLAGS := $(OPTFLAGS) $(ARCHFLAGS) $(BSPFLAGS) $(EXTRA_FLAGS)
CXXFLAGS := $(CFLAGS) -fno-exceptions -fno-unwind-tables -fno-rtti

# Add BSP sources to compilation
BSP_SRCS := $(shell find $(BSP_DIR) -name '*.c') $(shell find $(BSP_DIR) -name '*.S')
BSP_C := $(filter %.c, $(BSP_SRCS))
BSP_AS := $(filter %.S, $(BSP_SRCS))
T_SRCS := $(realpath $(SRCS)) $(BSP_SRCS)

# Set Source objects
ASRCS := $(filter %.S, $(T_SRCS))
CSRCS := $(filter %.c, $(T_SRCS))
CPPSRCS := $(filter %.cc %.cpp, $(T_SRCS))
OBJS := \
	$(CPPSRCS:%.cpp=$(BUILD_DIR)/%.o) \
	$(CSRCS:%.c=$(BUILD_DIR)/%.o) \
	$(ASRCS:%.S=$(BUILD_DIR)/%.o)

# If cpp sources present, target is cpp
ifeq ($(CPPSRCS),)
LN := $(CC) $(CFLAGS)
else
LN := $(CXX) $(CXXFLAGS)
endif

# Link final elf file
$(BUILD_DIR)/main.elf: $(OBJS)
	@mkdir -p $(@D)
	$(LN) $(OBJS) -o $@

# Linker script generation rule
$(BUILD_DIR)/linker.lds:
	@mkdir -p $(@D)
	$(CC) -E -P -x c -I $(BSP_DIR) $(BSP_DIR)/linker.lds.in > $(BUILD_DIR)/linker.lds

# Custom assembly parser
$(BUILD_DIR)/main.dump: $(BUILD_DIR)/main.elf
	@mkdir -p $(@D)
	python $(BSP_DIR)/disassembly.py $< > $@

# Basic build C/C++ build rules
$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.S
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@
