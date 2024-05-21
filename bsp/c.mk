# Makefile for compilation of C/C++ programs for RISC-V platform
SRCS ?= 
BUILD_DIR ?= build
CPP_TARGET ?= 0
BSP_DIR ?= bsp
BSP_BUILD_DIR ?= $(BUILD_DIR)/bsp

# C Compiler definitions
CROSS := riscv32-unknown-elf-
CC := $(CROSS)gcc
CPPC := $(CROSS)g++
DUMP := $(CROSS)objdump

ifeq ($(CPP_TARGET), 1)
LINKER := $(CPPC)
else
LINKER := $(CC)
endif

# BSP must be compiled before
BSP_OBJS := $(shell find $(BSP_BUILD_DIR) -name '*.o')

# Set Source objects
CSRCS := $(filter %.c %.S, $(SRCS))
CPPSRCS := $(filter %.cc %.cpp, $(SRCS))
OBJS := \
	$(CPPSRCS:%.cpp=$(BUILD_DIR)/%.o) \
	$(CSRCS:%.c=$(BUILD_DIR)/%.o) \
	$(ASRCS:%.S=$(BUILD_DIR)/%.o)

# Compiler flags
CFLAGS := \
	-fdata-sections -ffunction-sections -Wl,--gc-sections,-S \
	-Wall -O3 -march=rv32g -mabi=ilp32 -mno-div \
	-fopt-info-optimized=$(BUILD_DIR)/comp_report.txt \
	-I $(BSP_DIR)/include \
	-ffreestanding -nostartfiles -T $(BSP_BUILD_DIR)/linker.lds \
	$(C_EXTRA_FLAGS)

$(BUILD_DIR)/main.dump: $(BUILD_DIR)/main.elf
	@mkdir -p $(@D)
	@$(DUMP) -D $< > $(BUILD_DIR)/main.dump

$(BUILD_DIR)/main.elf: $(OBJS) $(BSP_OBJS)
	@mkdir -p $(@D)
	@$(LINKER) $(CFLAGS) $^ -o $@

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(@D)
	@$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(@D)
	@$(CPPC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.S
	@mkdir -p $(@D)
	@$(CC) $(CFLAGS) -c $< -o $@
