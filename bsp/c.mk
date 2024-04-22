# Makefile for compilation of C programs for RISC-V platform
INPUT_CSRCS ?= 
INPUT_ASRCS ?= 
BSP_DIR ?= ./bsp
TARGET_NAME ?= main

# C Compiler definitions
CROSS := riscv32-unknown-elf-
CC := $(CROSS)gcc
DUMP := $(CROSS)objdump

# Dir definitions
BUILD_DIR := build

# Source and object file names
CSRCS := $(shell find -wholename $(BSP_DIR)'/*.c') $(INPUT_CSRCS)
ASRCS := $(shell find -wholename $(BSP_DIR)'/*.S') $(INPUT_ASRCS)
OBJS := $(CSRCS:%.c=$(BUILD_DIR)/%.o) $(ASRCS:%.S=$(BUILD_DIR)/%.o)

# Compiler flags
CFLAGS := \
	-fdata-sections -ffunction-sections -Wl,--gc-sections,-S\
	-Wall -O3\
	-march=rv32g -mabi=ilp32 -mno-div\
	-fopt-info-optimized=$(BUILD_DIR)/comp_report.txt\
	-I $(BSP_DIR) $(INCLUDE_DIRS)\
	-ffreestanding -nostartfiles -T $(BUILD_DIR)/linker.lds\
	$(C_EXTRA_FLAGS)

.PHONY: c_all c_libs c_info c_clean c_dump c_libs

c_all: c_clean c_info c_dump

c_libs: c_clean c_info $(OBJS) 

c_info:
	@echo "--- C Info ---"
	@echo $(OBJS)
	@echo "CFLAGS -> $(CFLAGS)"
	@echo "--------------"

c_clean:
	@rm -rf $(BUILD_DIR)
	@rm -rf $(TARGET_NAME).dump
	@rm -rf comp_report.txt

c_dump: $(BUILD_DIR)/$(TARGET_NAME).elf
	@echo "DUMP $<"
	@$(DUMP) -D $< > $(BUILD_DIR)/$(TARGET_NAME).dump

$(BUILD_DIR)/$(TARGET_NAME).elf : $(OBJS)
	@echo "LD $@"
	@$(CC) -E -P -x c -I $(BSP_DIR) $(BSP_DIR)/linker.lds.in > $(BUILD_DIR)/linker.lds
	$(CC) $(CFLAGS) $^ -o $@

$(BUILD_DIR)/%.o: %.c
	@echo "CC $<"
	@mkdir -p $(@D)
	@$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.S
	@echo "CASM $<"
	@mkdir -p $(@D)
	@$(CC) $(CFLAGS) -c $< -o $@
