# Makefile for compilation of C programs for RISC-V platform
CSRCS ?= 
ASRCS ?= 
BUILD_DIR ?= build
TARGET_NAME ?= main
BSP_SRC_DIR ?= bsp
BSP_BUILD_DIR ?= build/bsp

# C Compiler definitions
CROSS := riscv32-unknown-elf-
CC := $(CROSS)gcc
DUMP := $(CROSS)objdump

# BSP must be compiled before
BSP_OBJS := $(shell find $(BSP_BUILD_DIR) -name '*.o')
OBJS := $(CSRCS:%.c=$(BUILD_DIR)/%.o) $(ASRCS:%.S=$(BUILD_DIR)/%.o)

# Compiler flags
CFLAGS := \
	-fdata-sections -ffunction-sections -Wl,--gc-sections,-S\
	-Wall -O3 -march=rv32g -mabi=ilp32 -mno-div\
	-fopt-info-optimized=$(BUILD_DIR)/$(TARGET_NAME)_comp_report.txt\
	-I $(BSP_SRC_DIR)\
	-ffreestanding -nostartfiles -T $(BSP_BUILD_DIR)/linker.lds\
	$(C_EXTRA_FLAGS)

$(BUILD_DIR)/$(TARGET_NAME).dump: $(BUILD_DIR)/$(TARGET_NAME).elf
	@mkdir -p $(@D)
	@$(DUMP) -D $< > $(BUILD_DIR)/$(TARGET_NAME).dump

$(BUILD_DIR)/$(TARGET_NAME).elf: $(OBJS) $(BSP_OBJS)
	@mkdir -p $(@D)
	@$(CC) $(CFLAGS) $^ -o $@

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(@D)
	@$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.S
	@mkdir -p $(@D)
	@$(CC) $(CFLAGS) -c $< -o $@
